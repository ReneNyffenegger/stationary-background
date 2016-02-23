use warnings;
use strict;

use PDF::API2;

use File::Basename;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

my $pdf_in_name = shift;
die "$pdf_in_name does not exist" unless -e $pdf_in_name;

my $pdf_out_name = shift;
die if -e $pdf_out_name;

my $pdf_out = new PDF::API2 (-file => $pdf_out_name) or die;

my $pdf_in  = PDF::API2->open ($pdf_in_name) or die;

my $background = $pdf_out -> image_jpeg(dirname(__FILE__) . '/../out/background-border.jpg');

for my $page_no (1 .. $pdf_in -> pages()) {

  # Create a new page
    my $page = $pdf_out -> page(0);

    my $gfx = $page->gfx;

    $gfx -> image($background, 5/mm, 5/mm, 200/mm, 287/mm);

#   my $page = $pdf_out -> addPage();

#   $page -> image($background, 5/mm, 5/mm);

    $pdf_out -> importpage($pdf_in, $page_no, $page);

}

$pdf_out -> save();
