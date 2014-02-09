RhythmDen
========================


Rhythm Den is a music player designed to stream media content from Dropbox.
[http://rhythmdenapp.com/](http://rhythmdenapp.com)


## Introduction

I originally created this App to allow me to stream music from multiple cloud storage providers but later on settled on just using Dropbox. It was a fun project that I enjoyed working on and I learned alot but unfortunately I don't have much time anymore to maintain it. So I decided to opensource it in case others would like to continue it and make it better.

I encourage forkers to rebrand this app under a different name because of how rigid Apple's App Store is. An honestly I don't even know how one would go about managing opensource software in Apples App Store. For details on the licensing see below.

## Documentation

To get started these are some of the things you'll need to change:

#### App Credentials

- You will need to create a [Dropbox App](https://www.dropbox.com/developers), [Bitly Key](http://dev.bitly.com/). You will find these defines in `RDAppDelegate.m` file.

        #define DROPBOX_APPKEY @""
        #define DROPBOX_APPSECRET @""
        #define BITLY_APPKEY @""
        #define BITLY_APPLOGIN @""
    
- You will need to create an [iTunes Key](http://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html) to do searches. Once you get a key make sure you append that id to the end of query string _(&at=YOUR_SEARCH_KEY)_. See `RDiTunesSearchService.m` file.
        
        #define ITUNES_SEARCH_SONG_QUERY @"https://itunes.apple.com/search?term=%@+%@+%@&media=music&entity=song&at="
		#define ITUNES_SEARCH_ALBUM_QUERY @"https://itunes.apple.com/search?term=%@+%@&media=music&entity=album&at="
		#define ITUNES_LOOKUP_QUERY @"https://itunes.apple.com/lookup?id=%@&media=music&entity=song&at="
		
- Update **CFBundleURLSchemes** URL Types for Dropbox in `RhythemDen-Info.plist` file
     
        <dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>rhythmden</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string></string>
			</array>
		</dict>
		
- Make sure you replace/update `RhythmDen.entitlements` file to reflect your App Developer credentials as well as enabling **iCloud**. See [Entitlement Key Reference](https://developer.apple.com/library/ios/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AboutEntitlements.html) on Apple's iOS Dev Center.

I'm pretty sure I've probably forgot some stuff so make sure you send me a message if you have any questions. Aside from that, dig in and have fun, because I certainly did!

## LICENSE

In summary, Have Fun & Share! For specifics see [link](LICENSE)

## Questions?

If you have any questions or comments please feel free to drop me a line :-).

Email: <donellesanders@gmail.com>
Follow Me: [@DonelleJr](https://twitter.com/DonelleJr)