%% @author Arjan Scherpenisse <arjan@scherpenisse.net>
%% @copyright 20104 Arjan Scherpenisse
%% @doc Augments audio media files with info from the echonest API

-module(mod_audio_echonest).
-author("Arjan Scherpenisse <arjan@scherpenisse.net>").

-mod_title("Echonest Audio file information").
-mod_description("Augments audio media files with info from the echonest API").
-mod_prio(800).

-include_lib("include/zotonic.hrl").

-export([observe_media_update_done/2, api_key/1]).

-define(UPLOAD_URL, "http://developer.echonest.com/api/v4/track/upload").
-define(TRACK_PROFILE_URL, "http://developer.echonest.com/api/v4/track/profile").


observe_media_update_done(#media_update_done{action=insert, id=Id, post_props=Props}, Context) ->
    case proplists:get_value(mime, Props) of
        "audio/" ++ _ ->
            lager:warning("Audio: ~p", [Id]),
            spawn_link(fun () -> identify(Id, Props, Context) end),
            undefined;
        _ ->
            undefined
    end;
observe_media_update_done(_, _Context) ->
    undefined.


identify(Id, Props, Context) ->

    spawn(fun() ->
                  timer:sleep(1000),
                  z_session_manager:broadcast(#broadcast{type="info", message="Audio analysis in progress, please wait.", title="Echonest"}, z_acl:sudo(Context))
          end),
    
    %% Upload file to EchoNest for Audio analysis
    %% curl -X POST "http://developer.echonest.com/api/v4/track/upload" -d "api_key=FILDTEOIK2HBORODV&url=http://example.com/audio.mp3"
    UploadUrl = ?UPLOAD_URL ++ "?api_key=" ++ mochiweb_util:quote_plus(api_key(Context)) ++ "&filetype=mp3",
    AudioFile = filename:join(z_path:media_archive(Context), proplists:get_value(filename, Props)),
    {ok, Payload} = file:read_file(AudioFile),

    case httpc:request(post, {UploadUrl, [], "application/octet-stream", Payload}, [], []) of
        {ok, {{_, 200, _}, _Headers, Body}} ->

            Track = get_track(mochijson2:decode(Body)),
            TrackId = proplists:get_value(<<"id">>, Track),

            %% Get deep audio information from the Echonest API
            %e.g. http://developer.echonest.com/api/v4/track/profile?api_key=FILDTEOIK2HBORODV&format=json&id=TRGOVKX128F7FA5920&bucket=audio_summary

            TrackUrl = ?TRACK_PROFILE_URL ++ "?api_key=" ++ mochiweb_util:quote_plus(api_key(Context))
                ++ "&format=json&bucket=audio_summary&id=" ++ mochiweb_util:quote_plus(z_convert:to_list(TrackId)),

            case httpc:request(TrackUrl) of
                {ok, {{_, 200, _}, _InfoHeaders, InfoBody}} ->

                    FullTrack = get_track(mochijson2:decode(InfoBody)),

                    case get_rsc_title(FullTrack) of
                        undefined ->
                            z_session_manager:broadcast(#broadcast{type="info", message="Audio analysis done, could not identify track.", title="Echonest"}, z_acl:sudo(Context)),
                            m_rsc:update(Id, [{echonest_info, {struct, FullTrack}}], Context);
                        Title ->
                            ?zInfo("Audio file information added for " ++ Title, Context),
                            z_session_manager:broadcast(#broadcast{type="info", message="Audio analysis done, found track: " ++ Title, title="Echonest"}, z_acl:sudo(Context)),
                            m_rsc:update(Id, [{title, Title}, {echonest_info, {struct, FullTrack}}], Context)
                    end;
                
                R ->
                    z_session_manager:broadcast(#broadcast{type="error", message="Audio analysis API failure.", title="Echonest"}, z_acl:sudo(Context)),
                    lager:warning("error: ~p", [R])
            end;

        R ->
            z_session_manager:broadcast(#broadcast{type="error", message="Audio analysis API failure.", title="Echonest"}, z_acl:sudo(Context)),
            lager:warning("error: ~p", [R]),
            error
    end.


get_rsc_title(FullTrack) ->
    Artist =  proplists:get_value(<<"artist">>, FullTrack),
    Title =  proplists:get_value(<<"title">>, FullTrack),
    case {Artist, Title} of
        {A, T} when is_binary(A) andalso is_binary(T) ->
            z_convert:to_list(A) ++ " - " ++ z_convert:to_list(T);
        {undefined, T} when is_binary(T) ->
            z_convert:to_list(T);
        _ ->
            undefined
    end.


get_track({struct, APIResponse}) ->
    {struct, Response} = proplists:get_value(<<"response">>, APIResponse),
    {struct, Track} = proplists:get_value(<<"track">>, Response),
    Track.
    

api_key(Context) ->
    z_convert:to_list(m_config:get_value(?MODULE, api_key, Context)).


