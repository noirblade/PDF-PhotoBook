#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  test.pl
#
#        USAGE:  ./test.pl  
#
#  DESCRIPTION:  Test Suite File
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Kail (), sickboy@anarchy.name
#      COMPANY:  Ergon
#      VERSION:  1.0
#      CREATED:  11/06/2009 11:16:42 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use PDF::PhotoBook;

my $book = new PDF::PhotoBook;

$book->SetTempDir('tmp');
    
my $layouts = [
            {'width'       => 500,
            'height'       => 800,
            'placeholders' => [
                            {
                            'type'        => 'image',          # Placeholder type image/text
                            'filepath'    => 'test.jpg',       # Image path
                            'width'       => 100,              # Placeholder width
                            'height'      => 300,              # Placeholder height
                            'x'           => 100,              # X cordinates
                            'y'           => 100,              # Y cordinates
                            'mask'        => 'test_mask.png',  # Optional. If we have frame we must apply transparency mask before adding it
                            'frame'       => 'test_frame.png', # Optional. If we have frame. 
                            'imageWidth'  => 100,              # For resizing the image
                            'imageHeight' => 300,              # For resizing the image
                            'imageX'      => 10,               # Optional. This is used to crop the image if we want to
                            'imageY'      => 20,               # Optional. This is used to crop the image if we want to
                            'flop'        => 1,                # Optional. If we want to flop the image
                            'degrees'     => 90,               # Optional. If we need a rotation
                            },
                            {
                            'type'     => 'text',           # Placeholder type image/text
                            'width'    => 300,              # Placeholder width
                            'height'   => 300,              # Placeholder height
                            'x'        => 0,                # X cordinates
                            'y'        => 500,              # Y cordinates
                            'ttf'      => 'arial.ttf',      # TTF font path
                            'text'     => 'Test text',      # Text content
                            'color'    => '#000000',        # Font color
                            'size'     => '32',             # Font size
                            'align'    => 'center',         # Text align in the placeholder - left/right/center
                            },
                        ],
            } 
            ]; 
$book->AddLayouts($layouts);
$book->Create('test.pdf');
