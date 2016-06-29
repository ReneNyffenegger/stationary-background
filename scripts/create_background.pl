use warnings;
use strict;

use Image::Magick;
use PDF::API2;
use Getopt::Long;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

GetOptions(
  'additional-text-has-changed' => \my $additional_text_has_changed
);

my $filename_227x191_png          = '..\temp\227x191_border-5mm.png';
my $filename_background_pixelized = '..\temp\background_2551x3579_pixelized.png';
my $filename_background_2551x3579 = '..\temp\background_2551x3579.png';

if (! $additional_text_has_changed) {

  unlink glob '../temp/*.*'; # Won't delete .gitignore
  unlink glob '../out/*.*'; # Won't delete .gitignore
  
# $ENV{PATH} .= 'C:\Program Files\ImageMagick-6.9.2-Q16;';
  
  
  # Create png from svg
  system('inkscape -f ..\input\136x191_border-5mm.svg -e ..\temp\136x191_border-5mm.png') and die;
  
  # Stretch png
  system('convert -resize 227x191! ..\temp\136x191_border-5mm.png ' . $filename_227x191_png) and die;
  
  create_pdf();
  
  # PDF -> PNG
  system('convert -density 300 ..\temp\background.pdf ' . $filename_background_pixelized) and die;

}
  
# Add Additional text
system('inkscape -f ..\input\2551x3579_additional-text_border-5mm.svg -e ' . $filename_background_2551x3579) and die;


# Check borders etc
#      http://stackoverflow.com/questions/23082308/cut-rectangle-from-the-image
#
# 1) 5mm Border
if (! $additional_text_has_changed) {
  # Use the *excess* files to check if the cut borders would contain some graphics.
  system ('convert ' . $filename_background_2551x3579 . ' -region 2362x3389+94+94  -alpha transparent ..\temp\background-border-excess.png') and die;
}
system ('convert ' . $filename_background_2551x3579 . ' -crop   2362x3389+94+94!                    ..\out\background-border.png') and die;

# 2) A4
if (! $additional_text_has_changed) {
  system ('convert ' . $filename_background_2551x3579 . ' -region 2480x3507+35+35  -alpha transparent ..\temp\background-a4-excess.png') and die;
}
system ('convert ' . $filename_background_2551x3579 . ' -crop   2480x3507+35+35!                    ..\out\background-a4.png') and die;

system ('convert ..\out\background-border.png -format jpg -flatten -background white ..\out\background-border.jpg') and die;

sub create_pdf { # {{{

  my $source_w =  227;
  my $source_h =  191;
  
  my $dest_w   = 216/mm;
  my $dest_h   = 303/mm;
  
  my $char_w = $dest_w / $source_w;
  my $char_h = $dest_h / $source_h;
  
  my $pdf = PDF::API2->new;
  
  my $courier_new      = $pdf->ttfont('c:\windows\Fonts\cour.ttf');
  my $courier_new_bold = $pdf->ttfont('c:\windows\Fonts\courbd.ttf');

  my $pdf_page = $pdf->page;

  $pdf_page->mediabox($dest_w, $dest_h); 
  
  my $image_in = new Image::Magick;
  $image_in -> Read($filename_227x191_png);
  

  my $func_char = sub { # {{{
  
    my $x     = shift;
    my $y     = shift;
    my $char  = shift;
    my $r     = shift;
    my $g     = shift;
    my $b     = shift;
  
  
    my $txt_char = $pdf_page->text;
  
    my $color;
  
    $color= sprintf("#%02x%02x%02x", $r, $g, $b);
  
    if ($r < 190 or $g < 190 or $b < 190) {
      $txt_char->font($courier_new_bold, 4.5/pt );
    }
    else {
      $txt_char->font($courier_new, 4.5/pt );
    }
    $txt_char->translate( $x * $dest_w/$source_w, $dest_h - $y*$dest_h/$source_h - 4.5/pt);
    $txt_char->fillcolor($color);
    $txt_char->text($char);
  
  }; # }}}

  
  for (my $x = 0; $x < $source_w; $x++) { # {{{
    print "x: $x\n";
    for (my $y = 0; $y < $source_h; $y++) {
  
  
      my @pixels = $image_in->GetPixels(
          width     => 1,
          height    => 1,
          x         => $x,
          y         => $y,
          map       =>'RGBA',
          normalize => 1
      );
  
      my ($r, $g, $b, $a) = (int($pixels[0] * 255),
                             int($pixels[1] * 255),
                             int($pixels[2] * 255),
                             int($pixels[3] * 255)
                            );

      next if ($r == 255 and $g == 255 and $b == 255);
  
      $func_char->($x, $y, int(rand() + 0.5), $r, $g, $b);
  
    }
  } # }}}
  
  $pdf->saveas('..\temp\background.pdf');

} # }}}
