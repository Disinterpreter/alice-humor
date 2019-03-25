use strict;
use warnings;
use Data::Dumper;
use JSON;
use LWP;
use LWP::UserAgent; 
use utf8;

use Plack::Request;


my $responsepattern = {
    "response" => {
        "end_session" => "true"
    },
    "session" => {
        
    },
    "version" => "1.0"
};


sub loadConfig {

    my $filename = shift;
    open my $handle, '<', $filename;

    my $config = {};
    while (my $row = <$handle>) {
        if ($row =~ m/^(\w+)=(.+)$/gm) {
            my $key = $1;
            my $param = $2;
            $param =~ s/\s+//g;
            $config->{$key} = $param;
        }
    }
    return $config;
}

my $config = loadConfig('.conf');
my $ua = LWP::UserAgent->new();

sub wall_get{
    my $clid = splice(@_, rand @_, 1);
    my $url = 'https://api.vk.com/method/wall.get';
    my $offset = int(rand(201952));
    my $send = [
            'access_token' => $config->{'VK'},
            'v' => '5.92',
            'count' => 1,
            'offset' => $offset,
            'owner_id' => $clid
    ];
    my $request = $ua->post( $url, $send);
    my $response = $request->decoded_content;
    warn(Dumper($response));
    my $json = decode_json($response);
    my $link;
    
    if (!defined $json->{'response'}->{'items'}->[0]) { 
            my $maxcount = $json->{'response'}->{'count'};
            my $send2 = [
            'access_token' => $config->{'VK'},
            'v' => '5.92',
            'count' => 1,
            'offset' => int(rand($maxcount)),
            'owner_id' => $clid
            ];
            my $secrequest = $ua->post( $url, $send2);
            my $secresponse = $secrequest->decoded_content;
            my $json2 = decode_json($secresponse);
            $link = $json2->{'response'}->{'items'}->[0]->{'text'};
            return $link;
    };
    $link = $json->{'response'}->{'items'}->[0]->{'text'};
    return $link;
}


my $app = sub {
    my $env = shift;
    my $ua      = LWP::UserAgent->new();

    my $req = Plack::Request->new($env);
    my $content = $req->content();
    my $jstring = decode_json($content);
    #warn (Dumper($content));
    if ($jstring->{'session'} && $jstring->{'session'}->{'user_id'} eq $config->{'YAUSER'}) {
        my $session_id = $jstring->{'session'}->{'session_id'};
        my $skill_id = $jstring->{'session'}->{'skill_id'};
        my $user_id = $jstring->{'session'}->{'user_id'};

        my $keyword = $jstring->{'request'}->{'nlu'}->{'tokens'}->[1];
        warn( $user_id );
        $responsepattern->{'session'}->{'session_id'} = $session_id;
        $responsepattern->{'session'}->{'skill_id'} = $skill_id;
        $responsepattern->{'session'}->{'user_id'} = $user_id;

        my $humor = wall_get(['-92876084', '-45491419']);
        if ( $humor eq '') { $humor = wall_get(['-92876084', '-45491419']); };
        $responsepattern->{'response'}->{'text'} = $humor;
        $responsepattern->{'response'}->{'tts'} = $humor;

        my $send = encode_json($responsepattern);
        return [
             '200',
             [ 'Content-Type' => 'text/html' ],
             [ $send ],
        ];
        #warn($session_id . " ; ". $skill_id . " ; ". $user_id . ";\n");

    } else {
         return [
             '200',
             [ 'Content-Type' => 'text/html' ],
             [ "ok" ],
        ];
    }
};
