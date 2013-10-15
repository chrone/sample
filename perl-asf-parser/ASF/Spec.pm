package ASF::Spec;
use strict;
use warnings;

my $instance;
sub new {
    my $class = shift;
    unless ($instance) {
        $instance = bless +{
            _guid      => +{ _guids() },
            _name      => +{ reverse _guids() },
            _structure => +{ _structure() },
        }, $class;
    }
    $instance;
}

sub name2guid { shift->{_guid}->{$_[0]} }
sub guid2name { shift->{_name}->{$_[0]} }
sub structure { shift->{_structure} }

sub _structure {
    # 3.1 Header Object (mandatory, one only)
    ASF_Header_Object => [
        [ 'Object ID'                => 128 ],
        [ 'Object Size'              =>  64 ],
        [ 'Number of Header Objects' =>  32 ],
        [ 'Reserved1'                =>   8 ],
        [ 'Reserved2'                =>   8 ],
        [ 'Header Objects'           => [ count => \'Number of Header Objects' ] => +{

        # 3.2 File Properties Object (mandatory, one only)
        ASF_File_Properties_Object => [
            [ 'Object ID'                => 128 ],
            [ 'Object Size'              =>  64 ],
            [ 'File ID'                  => 128 ],
            [ 'File Size'                =>  64 ],
            [ 'Creation Date'            =>  64 => 'time' ],
            [ 'Data Packets Count'       =>  64 ],
            [ 'Play Duration'            =>  64 ],
            [ 'Send Duration'            =>  64 ],
            [ 'Preroll'                  =>  64 ],
            [ 'Flags'                    =>  32 => [
                [ 'Broadcast Flag' =>  1 ],
                [ 'Seekable Flag'  =>  1 ],
                [ 'Reserved'       => 30 ],
            ]],
            [ 'Minimum Data Packet Size' =>  32 ],
            [ 'Maximum Data Packet Size' =>  32 ],
            [ 'Maximum Bitrate'          =>  32 ],
        ],

        # 3.3 Stream Properties Object (mandatory, one per stream)
        ASF_Stream_Properties_Object => [
            [ 'Object ID'                    => 128 ],
            [ 'Object Size'                  =>  64 ],
            [ 'Stream Type'                  => 128 ],
            [ 'Error Correction Type'        => 128 ],
            [ 'Time Offset'                  =>  64 ],
            [ 'Type-Specific Data Length'    =>  32 ],
            [ 'Error Correction Data Length' =>  32 ],
            [ 'Flags'                        =>  16 => [
                [ 'Stream Number'          => 7 ],
                [ 'Reserved'               => 8 ],
                [ 'Encrypted Content Flag' => 1 ],
            ]],
            [ 'Reserved'                     =>  32 ],
            [ 'Type-Specific Data'           => \'Type-Specific Data Length' => +{
                condition => 'Stream Type',
                ASF_Audio_Media => [
                    [ 'Codec ID / Format Tag'              => 16 => +{
                        0x0161 => 'Windows Media Audio',
                        0x0162 => 'Windows Media Audio 9 Professional',
                        0x0163 => 'Windows Media Audio 9 Lossless',
                        0x7A21 => 'GSM-AMR',
                        0x7A22 => 'GSM-AMR',
                    }],
                    [ 'Number of Channels'                 => 16 ],
                    [ 'Samples Per Second'                 => 32 ],
                    [ 'Average Number of Bytes Per Second' => 32 ],
                    [ 'Block Alignment'                    => 16 ],
                    [ 'Bits Per Sample'                    => 16 ],
                    [ 'Codec Specific Data Size'           => 16 ],
                    [ 'Codec Specific Data'                => \'Codec Specific Data Size' => +{
                        condition => 'Codec ID / Format Tag',
                        'Windows Media Audio' => [
                            [ 'Samples Per Block' => 32 ],
                            [ 'Encode Options'    => 16 ],
                            [ 'Super Block Align' => 32 ],
                        ],
                        'Windows Media Audio 9 Professional' => [
                            [ 'Samples Per Block' => 32 ],
                            [ 'Encode Options'    => 16 ],
                            [ 'Super Block Align' => 32 ],
                        ],
                        'Windows Media Audio 9 Lossless' => [
                            [ 'Samples Per Block' => 32 ],
                            [ 'Encode Options'    => 16 ],
                            [ 'Super Block Align' => 32 ],
                        ],
                    }],
                ],
                ASF_Video_Media => [
                    [ 'Encoded Image Width'  => 32 ],
                    [ 'Encoded Image Height' => 32 ],
                    [ 'Reserved Flags'       =>  8 ],
                    [ 'Format Data Size'     => 16 ],
                    [ 'Format Data'          => \'Format Data Size' => [
                        [ 'Format Data Size'            => 32 ],
                        [ 'Image Width'                 => 32 ],
                        [ 'Image Height'                => 32 ],
                        [ 'Reserved'                    => 16 ],
                        [ 'Bits Per Pixel Count'        => 16 ],
                        [ 'Compression ID'              => 32 ],
                        [ 'Image Size'                  => 32 ],
                        [ 'Horizontal Pixels Per Meter' => 32 ],
                        [ 'Vertical Pixels Per Meter'   => 32 ],
                        [ 'Colors Used Count'           => 32 ],
                        [ 'Important Colors Count'      => 32 ],
                        [ 'Codec Specific Data'         => undef ],
                    ]]
                ],
            }],
            [ 'Error Correction Data'        => \'Error Correction Data Length' ],
        ],

        # 3.4 Header Extension Object (mandatory, one only)
        ASF_Header_Extension_Object => [
            [ 'Object ID'                  => 128 ],
            [ 'Object Size'                =>  64 ],
            [ 'Reserved Field 1'           => 128 ],
            [ 'Reserved Field 2'           =>  16 ],
            [ 'Header Extension Data Size' =>  32 ],
            [ 'Header Extension Data'      => [ size => \'Header Extension Data Size' ] => +{

            # 4.1 Extended Stream Properties Object (optional, 1 per media stream)
            ASF_Extended_Stream_Properties_Object => [
                [ 'Object ID'                         => 128 ],
                [ 'Object Size'                       =>  64 ],
                [ 'Start Time'                        =>  64 ],
                [ 'End Time'                          =>  64 ],
                [ 'Data Bitrate'                      =>  32 ],
                [ 'Buffer Size'                       =>  32 ],
                [ 'Initial Buffer Fullness'           =>  32 ],
                [ 'Alternate Data Bitrate'            =>  32 ],
                [ 'Alternate Buffer Size'             =>  32 ],
                [ 'Alternate Initial Buffer Fullness' =>  32 ],
                [ 'Maximum Object Size'               =>  32 ],
                [ 'Flags'                             =>  32 => [
                    [ 'Reliable Flag'                =>  1 ],
                    [ 'Seekable Flag'                =>  1 ],
                    [ 'No Cleanpoints Flag'          =>  1 ],
                    [ 'Resend Live Cleanpoints Flag' =>  1 ],
                    [ 'Reserved Flags'               => 28 ]
                ]],
                [ 'Stream Number'                     =>  16 ],
                [ 'Stream Language ID Index'          =>  16 ],
                [ 'Average Time Per Frame'            =>  64 ],
                [ 'Stream Name Count'                 =>  16 ],
                [ 'Payload Extension System Count'    =>  16 ],
                [ 'Stream Names'                      => [ count => \'Stream Name Count' ] => [
                    [ 'Language ID Index'  => 16 ],
                    [ 'Stream Name Length' => 16 ],
                    [ 'Stream Name'        => \'Stream Name Length' => 'wchar' ],
                ]],
                [ 'Payload Extension Systems'         => [ count => \'Payload Extension System Count' ] => [
                    [ 'Extension System ID'          => 128 ],
                    [ 'Extension Data Size'          =>  16 ],
                    [ 'Extension System Info Length' =>  32 ],
                    [ 'Extension System Info'        => \'Extension System Info Length' ],
                ]],
            ],

            # 4.4 Stream Prioritization Object (optional, 0 or 1)
            ASF_Stream_Prioritization_Object => [
                [ 'Object ID'              => 128 ],
                [ 'Object Size'            =>  64 ],
                [ 'Priority Records Count' =>  16 ],
                [ 'Priority Records'       => [ count => \'Priority Records Count' ] => [
                    [ 'Stream Number'   => 16 ],
                    [ 'Mandatory Flags' =>  1 ],
                    [ 'Reserved Flags'  => 15 ],
                ]],
            ],

            # 4.6 Language List Object (optional, only 1)
            ASF_Language_List_Object => [
                [ 'Object ID'                  => 128 ],
                [ 'Object Size'                =>  64 ],
                [ 'Language ID Records Count'  =>  16 ],
                [ 'Language ID Records'        => [ count => \'Language ID Records Count' ] => [
                    [ 'Language ID Length' => 8 ],
                    [ 'Language ID'        => \'Language ID Length' => 'wchar' ],
                ]],
            ],

            # 4.7 Metadata Object (optional, 0 or 1)
            ASF_Metadata_Object => [
                [ 'Object ID'                 => 128 ],
                [ 'Object Size'               =>  64 ],
                [ 'Description Records Count' =>  16 ],
                [ 'Description Records'       => [ count => \'Description Records Count' ] => [
                    [ 'Reserved (Must Be Zero)' => 16 ],
                    [ 'Stream Number' => 16 ],
                    [ 'Name Length'   => 16 ],
                    [ 'Data Type'     => 16 => +{
                        0x0000 => 'Unicode string',
                        0x0001 => 'BYTE array',
                        0x0002 => 'BOOL',
                        0x0003 => 'DWORD',
                        0x0004 => 'QWORD',
                        0x0005 => 'WORD',
                    }],
                    [ 'Data Length'   => 32 ],
                    [ 'Name'          => \'Name Length' => 'wchar' ],
                    [ 'Data'          => \'Data Length' => +{
                        condition => 'Data Type',
                        'Unicode string' => 'wchar',
                        'BYTE array'     => undef,
                        'BOOL'           => undef,
                        'DWORD'          => undef,
                        'QWORD'          => undef,
                        'WORD'           => undef,
                    }],
                ]],
            ],

            # 4.12 Compatibility Object (optional, only 1)
            ASF_Compatibility_Object => [
                [ 'Object ID'   => 128 ],
                [ 'Object Size' =>  64 ],
                [ 'Profile'     =>   8 ],
                [ 'Mode'        =>   8 ],
            ],

            # 3.17 Padding Object (optional, 0 to many)
            ASF_Padding_Object => [
                [ 'Object ID'    => 128 ],
                [ 'Object Size'  =>  64 ],
                [ 'Padding Data' => undef ],
            ],

            }],
        ],

        # 3.5 Codec List Object (optional, one only)
        ASF_Codec_List_Object => [
            [ 'Object ID'           => 128 ],
            [ 'Object Size'         =>  64 ],
            [ 'Reserved'            => 128 ],
            [ 'Codec Entries Count' =>  32 ],
            [ 'Codec Entries'       => [ count => \'Codec Entries Count' ] => [
                [ 'Type'                     => 16 => +{
                    0x0001 => 'Video codec',
                    0x0002 => 'Audio codec',
                    0xFFFF => 'Unknown codec',
                }],
                [ 'Codec Name Length'        => 16 => 'nchars' ],
                [ 'Codec Name'               => \'Codec Name Length' => 'wchar' ],
                [ 'Codec Description Length' => 16 => 'nchars' ],
                [ 'Codec Description'        => \'Codec Description Length' => 'wchar' ],
                [ 'Codec Information Length' => 16 ],
                [ 'Codec Information'        => \'Codec Information Length' ],
            ]],
        ],

        # 3.8 Bitrate Mutual Exclusion Object (optional, 0 or 1)
        ASF_Bitrate_Mutual_Exclusion_Object => [
            [ 'Object ID'            => 128 ],
            [ 'Object Size'          =>  64 ],
            [ 'Exclusion Type'       => 128 ],
            [ 'Stream Numbers Count' =>  16 ],
            [ 'Stream Numbers'       => [ count => \'Stream Numbers Count' ] => [
                [ 'Stream Number' => 16 ],
            ]],
        ],

        # 3.10 Content Description Object (optional, one only)
        ASF_Content_Description_Object => [
            [ 'Object ID'          => 128 ],
            [ 'Object Size'        =>  64 ],
            [ 'Title Length'       =>  16 ],
            [ 'Author Length'      =>  16 ],
            [ 'Copyright Length'   =>  16 ],
            [ 'Description Length' =>  16 ],
            [ 'Rating Length'      =>  16 ],
            [ 'Title'              => \'Title Length'       => 'wchar' ],
            [ 'Author'             => \'Author Length'      => 'wchar' ],
            [ 'Copyright'          => \'Copyright Length'   => 'wchar' ],
            [ 'Description'        => \'Description Length' => 'wchar' ],
            [ 'Rating'             => \'Rating Length'      => 'wchar' ],
        ],

        # 3.11 Extended Content Description Object (optional, one only)
        ASF_Extended_Content_Description_Object => [
            [ 'Object ID'                 => 128 ],
            [ 'Object Size'               =>  64 ],
            [ 'Content Descriptors Count' =>  16 ],
            [ 'Content Descriptors'       => [ count => \'Content Descriptors Count' ] => [
                [ 'Descriptor Name Length'     => 16 ],
                [ 'Descriptor Name'            => \'Descriptor Name Length' => 'wchar' ],
                [ 'Descriptor Value Data Type' => 16 => +{
                    0x0000 => 'Unicode string',
                    0x0001 => 'BYTE array',
                    0x0002 => 'BOOL',
                    0x0003 => 'DWORD',
                    0x0004 => 'QWORD',
                    0x0005 => 'WORD',
                }],
                [ 'Descriptor Value Length'    => 16 ],
                [ 'Descriptor Value'           => \'Descriptor Value Length' => +{
                    condition => 'Descriptor Value Data Type',
                    'Unicode string' => 'wchar',
                    'BYTE array'     => undef,
                    'BOOL'           => undef,
                    'DWORD'          => undef,
                    'QWORD'          => undef,
                    'WORD'           => undef,
                }],
            ]],
        ],

        # 3.12 Stream Bitrate Properties Object (optional but recommended, one only)
        ASF_Stream_Bitrate_Properties_Object => [
            [ 'Object ID'             => 128 ],
            [ 'Object Size'           =>  64 ],
            [ 'Bitrate Records Count' =>  16 ],
            [ 'Bitrate Records'       => [ count => \'Bitrate Records Count' ] => [
                [ 'Flags'           => 16 => [
                    [ 'Stream Number' => 7 ],
                    [ 'Reserved'      => 9 ],
                ]],
                [ 'Average Bitrate' => 32 ],
            ]],
        ],
        }],
    ],
}

sub _guids {
    # 10.1 Top-level ASF object GUIDS
    ASF_Header_Object                        => '75B22630-668E-11CF-A6D9-00AA0062CE6C',
    ASF_Data_Object                          => '75B22636-668E-11CF-A6D9-00AA0062CE6C',
    ASF_Simple_Index_Object                  => '33000890-E5B1-11CF-89F4-00A0C90349CB',
    ASF_Index_Object                         => 'D6E229D3-35DA-11D1-9034-00A0C90349BE',
    ASF_Media_Object_Index_Object            => 'FEB103F8-12AD-4C64-840F-2A1D2F7AD48C',
    ASF_Timecode_Index_Object                => '3CB73FD0-0C4A-4803-953D-EDF7B6228F0C',

    # 10.2 Header Object GUIDs
    ASF_File_Properties_Object               => '8CABDCA1-A947-11CF-8EE4-00C00C205365',
    ASF_Stream_Properties_Object             => 'B7DC0791-A9B7-11CF-8EE6-00C00C205365',
    ASF_Header_Extension_Object              => '5FBF03B5-A92E-11CF-8EE3-00C00C205365',
    ASF_Codec_List_Object                    => '86D15240-311D-11D0-A3A4-00A0C90348F6',
    ASF_Script_Command_Object                => '1EFB1A30-0B62-11D0-A39B-00A0C90348F6',
    ASF_Marker_Object                        => 'F487CD01-A951-11CF-8EE6-00C00C205365',
    ASF_Bitrate_Mutual_Exclusion_Object      => 'D6E229DC-35DA-11D1-9034-00A0C90349BE',
    ASF_Error_Correction_Object              => '75B22635-668E-11CF-A6D9-00AA0062CE6C',
    ASF_Content_Description_Object           => '75B22633-668E-11CF-A6D9-00AA0062CE6C',
    ASF_Extended_Content_Description_Object  => 'D2D0A440-E307-11D2-97F0-00A0C95EA850',
    ASF_Content_Branding_Object              => '2211B3FA-BD23-11D2-B4B7-00A0C955FC6E',
    ASF_Stream_Bitrate_Properties_Object     => '7BF875CE-468D-11D1-8D82-006097C9A2B2',
    ASF_Content_Encryption_Object            => '2211B3FB-BD23-11D2-B4B7-00A0C955FC6E',
    ASF_Extended_Content_Encryption_Object   => '298AE614-2622-4C17-B935-DAE07EE9289C',
    ASF_Digital_Signature_Object             => '2211B3FC-BD23-11D2-B4B7-00A0C955FC6E',
    ASF_Padding_Object                       => '1806D474-CADF-4509-A4BA-9AABCB96AAE8',

    # 10.3 Header Extension Object GUIDs
    ASF_Extended_Stream_Properties_Object    => '14E6A5CB-C672-4332-8399-A96952065B5A',
    ASF_Advanced_Mutual_Exclusion_Object     => 'A08649CF-4775-4670-8A16-6E35357566CD',
    ASF_Group_Mutual_Exclusion_Object        => 'D1465A40-5A79-4338-B71B-E36B8FD6C249',
    ASF_Stream_Prioritization_Object         => 'D4FED15B-88D3-454F-81F0-ED5C45999E24',
    ASF_Bandwidth_Sharing_Object             => 'A69609E6-517B-11D2-B6AF-00C04FD908E9',
    ASF_Language_List_Object                 => '7C4346A9-EFE0-4BFC-B229-393EDE415C85',
    ASF_Metadata_Object                      => 'C5F8CBEA-5BAF-4877-8467-AA8C44FA4CCA',
    ASF_Metadata_Library_Object              => '44231C94-9498-49D1-A141-1D134E457054',
    ASF_Index_Parameters_Object              => 'D6E229DF-35DA-11D1-9034-00A0C90349BE',
    ASF_Media_Object_Index_Parameters_Object => '6B203BAD-3F11-48E4-ACA8-D7613DE2CFA7',
    ASF_Timecode_Index_Parameters_Object     => 'F55E496D-9797-4B5D-8C8B-604DFE9BFB24',
    ASF_Compatibility_Object                 => '26F18B5D-4584-47EC-9F5F-0E651F0452C9',
    ASF_Advanced_Content_Encryption_Object   => '43058533-6981-49E6-9B74-AD12CB86D58C',

    # 10.4 Stream Properties Object Stream Type GUIDs
    ASF_Audio_Media                          => 'F8699E40-5B4D-11CF-A8FD-00805F5C442B',
    ASF_Video_Media                          => 'BC19EFC0-5B4D-11CF-A8FD-00805F5C442B',
    ASF_Command_Media                        => '59DACFC0-59E6-11D0-A3AC-00A0C90348F6',
    ASF_JFIF_Media                           => 'B61BE100-5B4E-11CF-A8FD-00805F5C442B',
    ASF_Degradable_JPEG_Media                => '35907DE0-E415-11CF-A917-00805F5C442B',
    ASF_File_Transfer_Media                  => '91BD222C-F21C-497A-8B6D-5AA86BFC0185',
    ASF_Binary_Media                         => '3AFB65E2-47EF-40F2-AC2C-70A90D71D343',

    # 10.4.1 Web stream Type-Specific Data GUIDs
    ASF_Web_Stream_Media_Subtype             => '776257D4-C627-41CB-8F81-7AC7FF1C40CC',
    ASF_Web_Stream_Format                    => 'DA1E6B13-8359-4050-B398-388E965BF00C',

    # 10.5 Stream Properties Object Error Correction Type GUIDs
    ASF_No_Error_Correction                  => '20FB5700-5B55-11CF-A8FD-00805F5C442B',
    ASF_Audio_Spread                         => 'BFC3CD50-618F-11CF-8BB2-00AA00B4E220',

    # 10.6 Header Extension Object GUIDs
    ASF_Reserved_1                           => 'ABD3D211-A9BA-11cf-8EE6-00C00C205365',

    # 10.7 Advanced Content Encryption Object System ID GUIDs
    ASF_Content_Encryption_System_Windows_Media_DRM_Network_Devices
                                             => '7A079BB6-DAA4-4e12-A5CA-91D38DC11A8D',

    # 10.8 Codec List Object GUIDs
    ASF_Reserved_2                           => '86D15241-311D-11D0-A3A4-00A0C90348F6',

    # 10.9 Script Command Object GUIDs
    ASF_Reserved_3                           => '4B1ACBE3-100B-11D0-A39B-00A0C90348F6',

    # 10.10 Marker Object GUIDs
    ASF_Reserved_4                           => '4CFEDB20-75F6-11CF-9C0F-00A0C90349CB',

    # 10.11 Mutual Exclusion Object Exclusion Type GUIDs
    ASF_Mutex_Language                       => 'D6E22A00-35DA-11D1-9034-00A0C90349BE',
    ASF_Mutex_Bitrate                        => 'D6E22A01-35DA-11D1-9034-00A0C90349BE',
    ASF_Mutex_Unknown                        => 'D6E22A02-35DA-11D1-9034-00A0C90349BE',

    # 10.12 Bandwidth Sharing Object GUIDs
    ASF_Bandwidth_Sharing_Exclusive          => 'AF6060AA-5197-11D2-B6AF-00C04FD908E9',
    ASF_Bandwidth_Sharing_Partial            => 'AF6060AB-5197-11D2-B6AF-00C04FD908E9',

    # 10.13 Standard Payload Extension System GUIDs
    ASF_Payload_Extension_System_Timecode
                                             => '399595EC-8667-4E2D-8FDB-98814CE76C1E',
    ASF_Payload_Extension_System_File_Name
                                             => 'E165EC0E-19ED-45D7-B4A7-25CBD1E28E9B',
    ASF_Payload_Extension_System_Content_Type
                                             => 'D590DC20-07BC-436C-9CF7-F3BBFBF1A4DC',
    ASF_Payload_Extension_System_Pixel_Aspect_Ratio
                                             => '1B1EE554-F9EA-4BC8-821A-376B74E4C4B8',
    ASF_Payload_Extension_System_Sample_Duration
                                             => 'C6BD9450-867F-4907-83A3-C77921B733AD',
    ASF_Payload_Extension_System_Encryption_Sample_ID
                                             => '6698B84E-0AFA-4330-AEB2-1C0A98D7A44D',
    ASF_Payload_Extension_System_Degradable_JPEG
                                             => '00E1AF06-7BEC-11D1-A582-00C04FC29CFB',
}

1;
