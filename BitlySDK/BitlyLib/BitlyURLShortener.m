//
//  BitlyURLShortener.m
//  TwitterTest
//
//  Created by Tracy Pesin on 6/20/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyURLShortener.h"
#import "BitlyDebug.h"
#import "BitlyRequest.h"

@interface BitlyURLShortener() <BitlyRequestDelegate> {
    NSRegularExpression *urlRegex;
}

@property (nonatomic, retain) NSRegularExpression *urlRegex;
@property (nonatomic, retain) NSString *longText;
@property (nonatomic, retain) NSString *shortenedText;
@property (nonatomic, retain) NSMutableArray *bitlyRequests;
@property (nonatomic, retain) NSMutableDictionary *shortenedDict;
@property (nonatomic, retain) NSMutableArray *shortenQueue;

- (void)finishedShortening;
- (NSArray *)urlsInText:(NSString *)text;

@end

@implementation BitlyURLShortener

@synthesize delegate;
@synthesize shortenedText;
@synthesize bitlyRequests;
@synthesize shortenedDict;
@synthesize shortenQueue;
@synthesize urlRegex;
@synthesize longText;

- (void)dealloc {
    
    for (BitlyRequest *req in bitlyRequests) {
        req.delegate = nil;
    }
    [bitlyRequests release];
    [shortenedText release];
    [shortenedDict release];
    [shortenQueue release];
    
    [super dealloc];
}

- (id)init {
    if (self = [super init]) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
        self.shortenedDict = dict;
        [dict release];
        
        NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:4];
        self.shortenQueue = arr;
        [arr release];
    }
    return self;
}

- (NSRegularExpression *)urlRegex {
    
    if (urlRegex) {
        return urlRegex;
    } else {
        
        NSError *error = nil;
        
        //Brought over from the bitly site
        NSString *protocolPattern = @"(?:(https?|ftp|itms)://)";
        NSString *ipPattern = @"(?:[0-9]{1,3}\\.){3}(?:[0-9]{1,3})";
        NSString *idnTLDPattern = @"\u0645\u0635\u0631|\u0440\u0444|\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629|\u0627\u0645\u0627\u0631\u0627\u062a|xn--wgbh1c|xn--p1ai|xn--mgberp4a5d4ar|xn--mgbaam7a8h";
        
        NSString *idnFutureTLDPattern = @"\u4e2d\u56fd|\u4e2d\u570b|\u9999\u6e2f|\u0627\u0644\u0627\u0631\u062f\u0646|\u0641\u0644\u0633\u0637\u064a\u0646|\u0642\u0637\u0631|\u0dbd\u0d82\u0d9a\u0dcf|\u0b87\u0bb2\u0b99\u0bcd\u0b95\u0bc8|\u53f0\u7063|\u53f0\u6e7e|\u0e44\u0e17\u0e22|\u062a\u0648\u0646\u0633|xn--fiqs8S|xn--fiqz9S|xn--j6w193g|xn--mgbayh7gpa|xn--ygbi2ammx|xn--wgbl6a|xn--fzc2c9e2c|xn--xkc2al3hye2a|xn--kpry57d|xn--kprw13d|xn--o3cw4h|xn--pgbs0dh";
        
        NSString *idnTestTLDPattern = @"\u0625\u062e\u062a\u0628\u0627\u0631|\u0622\u0632\u0645\u0627\u06cc\u0634\u06cc|\u6d4b\u8bd5|\u6e2c\u8a66|\u0438\u0441\u043f\u044b\u0442\u0430\u043d\u0438\u0435|\u092a\u0930\u0940\u0915\u094d\u0937\u093e|\u03b4\u03bf\u03ba\u03b9\u03bc\u03ae|\ud14c\uc2a4\ud2b8|\u05d8\u05e2\u05e1\u05d8|\u30c6\u30b9\u30c8|\u0baa\u0bb0\u0bbf\u0b9f\u0bcd\u0b9a\u0bc8|xn--kgbechtv|xn--hgbk6aj7f53bba|xn--0zwm56d|xn--g6w251d|xn--80akhbyknj4f|xn--11b5bs3a9aj6g|xn--jxalpdlp|xn--9t4b11yi5a|xn--deba0ad|xn--zckzah|xn--hlcj6aya9esc7a";
        
        NSString *tldPattern = [NSString stringWithFormat:@"(?:[^\\s\\!\"\\#\\$\\%\\&\\'\\(\\)\\*\\+\\,\\.\\/\\:\\;\\<\\=\\>\\?\\@\\\\\\[\\]\\^\\_\\`\\{\\|\\}\\~]+\\.)+(?:aero|arpa|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|local|example|invalid|test|%@|%@|%@|[a-z]{2})(?::[0-9]+)?", idnTLDPattern, idnFutureTLDPattern, idnTestTLDPattern];
        
        NSString *domainPattern = [NSString stringWithFormat:@"(?:%@|%@)", tldPattern, ipPattern];
        
        NSString *pathPattern = @"(?:\\/?[\\S]+)";
        
        NSString *fullUriPattern = [NSString stringWithFormat:@"(%@%@%@)", protocolPattern, domainPattern, pathPattern];
        
        self.urlRegex = [NSRegularExpression regularExpressionWithPattern:fullUriPattern options:NSRegularExpressionCaseInsensitive error:&error];
        
        if (error) {
            BitlyLog(@"Error creating url regex, shouldn't happen since the inputs are constant: %@", [error localizedDescription]);
        }
        return urlRegex;
    }
}

- (NSArray *)urlsInText:(NSString *)text {
    
    NSMutableArray *allURLs = [NSMutableArray arrayWithCapacity:4];
    
    [self.urlRegex enumerateMatchesInString:text 
                            options:0 
                              range:NSMakeRange(0, [text length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                             NSRange matchRange = [match range];
                             NSString *url = [text substringWithRange:matchRange];
                             BitlyLog(@"Match: %@",url);
                             [allURLs addObject:url];
                         }];
    
    return allURLs;
}


- (void)shortenLinksInText:(NSString *)text {
    self.longText = text;
    self.shortenedText = text;
    
    NSArray *allURLs = [self urlsInText:text];
    
    for (NSString *urlString in allURLs) {
        if  ([[self.shortenedDict allKeys] containsObject:urlString] ||
             [[self.shortenedDict allValues] containsObject:urlString]) {
            //Already shortened
        } else if ([self.shortenQueue containsObject:urlString] ) {
            //In process of shortening
        } else {
            [self.shortenQueue addObject:urlString];
        }
    }
    
    if (self.shortenQueue.count == 0) {
        [self finishedShortening];
    } else {
        for (NSString *urlString in self.shortenQueue) {
            [self shortenURL:[NSURL URLWithString:urlString]];
        }
    }
}

- (void)shortenURL:(NSURL *)URL {
    BitlyRequest *request = [[BitlyRequest alloc] initWithURL:URL];
    request.delegate = self;
    if (!bitlyRequests) {
        NSMutableArray *reqs = [[NSMutableArray alloc] initWithCapacity:4];
        self.bitlyRequests = reqs;
        [reqs release];
    }
    [bitlyRequests addObject:request];
    [request release];
    [request start];
}


- (void)finishedShortening {
    if ([self.delegate respondsToSelector:@selector(bitlyURLShortenerDidShortenText:oldText:text:linkDictionary:)]) {
        [self.delegate bitlyURLShortenerDidShortenText:self 
                                                oldText:self.longText
                                                text:self.shortenedText
                                         linkDictionary:self.shortenedDict];
    }
    
}

#pragma mark BitlyRequestDelegate
- (void)bitlyRequestSucceeded:(BitlyRequest *)bitlyRequest 
                   forLongURL:(NSURL *)longURL 
           withShortURLString:(NSString *)shortURLString 
                 responseData:(NSDictionary *)data {
    
    BitlyLog(@"Bitly request succeeded for longURL %@, shortURL is %@", longURL, shortURLString); 
    if ([self.delegate respondsToSelector:@selector(bitlyURLShortenerDidShortenURL:longURL:shortURLString:)]) {
        [self.delegate bitlyURLShortenerDidShortenURL:self longURL:longURL shortURLString:shortURLString];
    }
    
    
    //We are shortening all URLs in a block of text, not just one URL
    if (self.longText) {
        [self.shortenedDict setValue:shortURLString forKey:[longURL absoluteString]];
        
        self.shortenedText = [self.shortenedText stringByReplacingOccurrencesOfString:[longURL absoluteString] withString:shortURLString];
        
        [self.shortenQueue removeObject:[longURL absoluteString]];
        if (self.shortenQueue.count == 0) {
            [self finishedShortening];
        }
    }
}


- (void)bitlyRequest:(BitlyRequest *)bitlyRequest failedForLongURL:(NSURL *)url statusCode:(NSInteger)statusCode statusText:(NSString *)statusText
{
    BitlyLog(@"Bitly shortening failed for long url: %@ with status code %d, statusText: %@ ", url, statusCode, statusText);
    if ([self.delegate respondsToSelector:@selector(bitlyURLShortener:didFailForLongURL:statusCode:statusText:)]) {
        [self.delegate bitlyURLShortener:self didFailForLongURL:url statusCode:statusCode statusText:statusText];
    }
    
    [self.shortenQueue removeObject:[url absoluteString]];
    if (self.shortenQueue.count == 0) {
        [self finishedShortening];
    }
    
}

@end
