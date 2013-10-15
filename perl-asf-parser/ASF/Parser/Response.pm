package ASF::Parser::Response;
use strict;
use warnings;

sub new {
    my ( $class, $object ) = @_;
    bless +{ object => $object }, $class;
}

sub _h         { shift->{object}->{ASF_Header_Object}->{'Header Objects'} }

sub _file      { shift->_h->{ASF_File_Properties_Object} }
sub _codec     { shift->_h->{ASF_Codec_List_Object}->{'Codec Entries'} }
sub _stream    { shift->_h->{ASF_Stream_Properties_Object} }
sub _ex        { shift->_h->{ASF_Header_Extension_Object}->{'Header Extension Data'} }

sub _stream_ex { shift->_ex->{ASF_Extended_Stream_Properties_Object} }

# TODO: Multi Bitrate
sub _codec_index {
    my $self = shift;
    unless ($self->{_codec_index}) {
        my $codecs = $self->_codec;
        my %codec_idx;
        $codec_idx{ $codecs->[$_]->{'Type'} } ||= $_ foreach 0..$#{$codecs};
        $self->{_codec_index} = \%codec_idx;
    }
    $self->{_codec_index}
}

sub _stream_index {
    my $self = shift;
    unless ($self->{_stream_index}) {
        my $streams = $self->_stream;
        my %stream_idx;
        $stream_idx{ $streams->[$_]->{'Stream Type'} } ||= $_ foreach 0..$#{$streams};
        $self->{_stream_index} = \%stream_idx;
    }
    $self->{_stream_index}
}

sub _audio_codec     { $_[0]->_codec    ->[$_[0]->_codec_index ->{'Audio codec'}] }
sub _video_codec     { $_[0]->_codec    ->[$_[0]->_codec_index ->{'Video codec'}] }
sub _audio_stream    { $_[0]->_stream   ->[$_[0]->_stream_index->{'ASF_Audio_Media'}]->{'Type-Specific Data'} }
sub _video_stream    { $_[0]->_stream   ->[$_[0]->_stream_index->{'ASF_Video_Media'}]->{'Type-Specific Data'} }
sub _audio_stream_ex { $_[0]->_stream_ex->[$_[0]->_stream_index->{'ASF_Audio_Media'}] }
sub _video_stream_ex { $_[0]->_stream_ex->[$_[0]->_stream_index->{'ASF_Video_Media'}] }

sub audio_codec      { shift->_audio_codec->{'Codec Name'} }
sub audio_codec_desc { shift->_audio_codec->{'Codec Description'} }
sub audio_samplerate { shift->_audio_stream->{'Samples Per Second'} }
sub audio_channels   { shift->_audio_stream->{'Number of Channels'} }
sub audio_bitrate    { shift->_audio_stream_ex->{'Data Bitrate'} }

sub audio_kbps { sprintf   '%d', shift->audio_bitrate    / 1000 }
sub audio_khz  { sprintf '%.1f', shift->audio_samplerate / 1000 }

sub video_codec      { shift->_video_codec->{'Codec Name'} }
sub video_codec_desc { shift->_video_codec->{'Codec Description'} }
sub video_width      { shift->_video_stream->{'Encoded Image Width'} }
sub video_height     { shift->_video_stream->{'Encoded Image Height'} }
sub video_bitrate    { shift->_video_stream_ex->{'Data Bitrate'} }
sub video_framerate  { sprintf '%.3f', 1e+7 / shift->_video_stream_ex->{'Average Time Per Frame'} }

sub video_kbps      { sprintf   '%d', shift->video_bitrate / 1000 }
sub video_size      { $_[0]->video_width . ' x ' . $_[0]->video_height }

sub audio_desc {
    my $self = shift;
    sprintf('%s / %s', $self->audio_codec, $self->audio_codec_desc);
}

sub video_desc {
    my $self = shift;
    my $codec = $self->video_codec ne 'VC-1' ? $self->video_codec : $self->video_codec_desc;
    sprintf('%s / %s kbps, %s, %s fps', $codec, $self->video_kbps, $self->video_size, $self->video_framerate);
}

sub preroll       { shift->_file->{'Preroll'} }
sub file_id       { shift->_file->{'File ID'} }
sub creation_date { shift->_file->{'Creation Date'} }
sub max_bitrate   { shift->_file->{'Maximum Bitrate'} }
sub file_id_by_binary { guid2binary( shift->file_id ) }

sub guid2binary {
    my $guid = shift;
    $guid =~ s/-//g;
    pack( 'VvvNN', unpack( 'NnnNN', pack( 'H*', $guid ) ) );
}

1;
