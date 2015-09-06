package Smartphone::Asset;

use strict;
use warnings;

use MT::Util qw(epoch2ts perl_sha1_digest_hex);
use Smartphone::Device;

sub rename_if_exists {
    my ( $cb, $app, $fmgr, $path_info ) = @_;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    my $local_file = File::Spec->catfile(
        @$path_info{qw(rootPath relativePath basename)} );
    if ( $fmgr->exists($local_file) ) {
        my $ext = (
            File::Basename::fileparse(
                $path_info->{basename},
                qr/\.[A-Za-z0-9]+$/
            )
        )[2];

        $path_info->{basename} = perl_sha1_digest_hex(
            join( '-',
                epoch2ts( $app->blog, time ), $app->remote_ip,
                $path_info->{basename} )
        ) . $ext;
    }
}

sub fix_orientation {
    my ( $cb, $obj ) = @_;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    eval { require Image::ExifTool; };
    return 1 if $@;    # Never rotate

    my $exif_tool = new Image::ExifTool;
    my $file_path = $obj->file_path;
    my $fmgr = $obj->blog ? $obj->blog->file_mgr : MT::FileMgr->new('Local');
    my $img_data = $fmgr->get_data( $file_path, 'upload' );

    $exif_tool->ExtractInfo( \$img_data );
    my $o = $exif_tool->GetInfo('Orientation')->{'Orientation'};
    if ( $o && ( $o ne 'Horizontal (normal)' && $o !~ /^Unknown/i ) ) {
        $exif_tool->SetNewValue(
            Orientation => $o,
            DelValue    => 1
        );
        $exif_tool->WriteInfo( \$img_data );

        my $img = MT::Image->new( Data => $img_data );

        my ( $blob, $width, $height ) = do {
            if ( $o eq 'Mirror horizontal' ) {
                $img->flipVertical();
            }
            elsif ( $o eq 'Rotate 180' ) {
                $img->rotate( Degrees => 180 );
            }
            elsif ( $o eq 'Mirror vertical' ) {
                $img->flipHorizontal();
            }
            elsif ( $o eq 'Mirror horizontal and rotate 270 CW' ) {
                $img->flipVertical();
                $img->rotate( Degrees => 270 );
            }
            elsif ( $o eq 'Rotate 90 CW' ) {
                $img->rotate( Degrees => 90 );
            }
            elsif ( $o eq 'Mirror horizontal and rotate 90 CW' ) {
                $img->flipVertical();
                $img->rotate( Degrees => 90 );
            }
            elsif ( $o eq 'Rotate 270 CW' ) {
                $img->rotate( Degrees => 270 );
            }
        };
        $fmgr->put_data( $blob, $file_path, 'upload' );
        $obj->image_width($width);
        $obj->image_height($height);
    }

    1;
}

1
