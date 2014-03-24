Echonest API for Zotonic
========================

This is a Zotonic module which hooks into media files uploads and
augments any uploaded audio media files with info from the echonest
API.

After the upload of any audio media file, it calls the Echonest API to
identiy the uploaded MP3 file. After identification, it will store the
found metadata in the `rsc` record of the audio file, ready for use in
Zotonic templates.

    {
            "analyzer_version": "3.01a", 
            "artist": "How to Destroy Angels", 
            "audio_md5": "97507e1eeda3e62abeabcc8dd51e6bd6", 
            "audio_summary": {
                "analysis_url": "https://echonest-analysis.s3.amazonaws.com:443/TR/TRGOVKX128F7FA5920/3/full.json?Signature=5RpVgJbbI9V9GyWApJnYGlMcTfw%3D&Expires=1308071436&AWSAccessKeyId=AKIAJRDFEY23UEVW42BQ", 
                "danceability": 0.59608747988903843, 
                "duration": 240.27383, 
                "energy": 0.74113818413872323, 
                "key": 2, 
                "loudness": -6.0359999999999996, 
                "mode": 1, 
                "tempo": 124.033, 
                "time_signature": 4
            }, 
            "bitrate": 320, 
            "id": "TRGOVKX128F7FA5920", 
            "md5": "cd9276287838f11f2d7f39cd10391195", 
            "release": "How to Destroy Angels", 
            "samplerate": 44100, 
            "status": "complete", 
            "title": "Fur Lined"
        }
    }


Configuration
-------------

The config key `mod_audio_echonest.api_key` needs to contain a valid Echonest API key, which can be obtained from this URL: https://developer.echonest.com/account/register 


Known issues
------------

* It only works for MP3 files currently.

