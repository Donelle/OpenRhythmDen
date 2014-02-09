//
//  RDAboutViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 10/7/13.
//
//

#import "RDAboutViewController.h"
#import "RDMusicResourceCache.h"
#import "UIImage+RhythmDen.h"
#import "UIColor+RhythmDen.h"



NSString * const kInfoTitle = @"Title";
NSString * const kInfoAuthor = @"Author";
NSString * const kInfoLicense = @"License";
NSString * const kInfoLicenseTextSize = @"LicenseTextSize";
NSString * const kInfoUrl = @"Url";


@interface RDAboutTableViewCell : UITableViewCell
@property (weak, nonatomic) NSDictionary * data;
@end

@implementation RDAboutTableViewCell {
    UILabel * _titleLabel;
    UILabel * _authorLabel;
    UILabel * _licenseLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        CGSize cellSize = self.bounds.size;
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cellSize.width, 20)];
        _titleLabel.font =[UIFont boldSystemFontOfSize:20];
        _titleLabel.textColor = cache.darkBackColor;
        [self addSubview:_titleLabel];
        
        _authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _titleLabel.bounds.size.height + 5, cellSize.width, 20)];
        _authorLabel.font = [UIFont systemFontOfSize:15];
        _authorLabel.textColor = cache.darkBackColor;
        [self addSubview:_authorLabel];
        
        CGRect authorRect = _authorLabel.frame;
        _licenseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, authorRect.origin.y + authorRect.size.height, cellSize.width, 0)];
        _licenseLabel.font = [UIFont systemFontOfSize:14];
        _licenseLabel.textColor = cache.darkBackColor;
        _licenseLabel.numberOfLines = 100;
        [self addSubview:_licenseLabel];

    }
    return self;
}

- (void)setData:(NSDictionary *)data
{
    _data = data;
    [self setNeedsLayout];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _titleLabel.text = [_data objectForKey:kInfoTitle];
    _authorLabel.text = [_data objectForKey:kInfoAuthor];
    _licenseLabel.text = [_data objectForKey:kInfoLicense];
    
    CGSize licenseSize = [(NSValue *)[_data objectForKey:kInfoLicenseTextSize] CGSizeValue];
    CGPoint licensePos = _licenseLabel.frame.origin;
    _licenseLabel.frame = CGRectMake(licensePos.x, licensePos.y, licenseSize.width, licenseSize.height);
}


@end


@interface RDAboutViewController ()
- (NSString *)loadFileFromBundle:(NSString *)resourceName;
- (CGSize)size:(CGSize)constraint withText:(NSString *)text;

@end

@implementation RDAboutViewController
{
    NSMutableArray * _contributions;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    //
    // Set up the title
    //
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 30)];
    title.font = [UIFont fontWithName:@"Ubuntu Condensed" size:25];
    title.textColor =  [UIColor colorWithRed:199.0/255.0 green:164.0/255.0 blue:130.0/255.0 alpha:1.0];
    title.backgroundColor = [UIColor clearColor];
    title.text = @"About";
    self.navigationItem.titleView = title;
    
    UIColor * textColor = [cache.darkBackColor lighterColor];
    //
    // Setup container
    //
    _containerView.clipsToBounds = YES;
    _containerView.layer.cornerRadius = 10.0f;
    _containerView.backgroundColor = cache.lightBackColor;
    //
    // Setup Version
    //
    NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString * build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    _appVersionLabel.text = [NSString stringWithFormat:@"Rhythm Den v%@ (Build %@)", version, build];
    _appVersionLabel.textColor = textColor;
    _descriptionLabel.textColor = textColor;
    //
    // Setup Logo
    //
    CGSize logoSize = cache.missingCoverArtImage.size;
    UIImage * logo = [cache.missingCoverArtImage crop:CGRectMake(5, 5, logoSize.width - 20, logoSize.height - 20)];
    _logoImageView.image = [logo tintColor:textColor];
    //
    // Setup the close button
    //
    _closeButton.backgroundColor = cache.buttonBackgroundColor;
    _closeButton.layer.cornerRadius = 5.0f;
    [_closeButton setTitleColor:cache.buttonTextColor forState:UIControlStateNormal];
    //
    // Setup the contributions
    //
    _contributions = [NSMutableArray array];
    //
    // ActionSheetPicker Setup
    //
    NSString * license = [self loadFileFromBundle:@"ActionSheetPicker-LICENSE"];
    NSMutableDictionary * info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"ActionSheetPicker", kInfoTitle, @"Tim Cinel", kInfoAuthor, license, kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // MSCellAccessory Setup
    //
    license = [self loadFileFromBundle:@"MSCellAccessory-LICENSE"];
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"MSCellAccessory", kInfoTitle, @"Shim Min", kInfoAuthor, license, kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // Tapku-Library Setup
    //
    license = [self loadFileFromBundle:@"Tapku-Library-LICENSE"];
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Tapku Library (TKAlertCenter)", kInfoTitle, @"Devin Ross", kInfoAuthor, license, kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // GPUImage Setup
    //
    license = [self loadFileFromBundle:@"GPUImage-LICENSE"];
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"GPUImage", kInfoTitle, @"Brad Larson", kInfoAuthor, license, kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // JSONKit Setup
    //
    license = @"JSONKit is dual licensed under either the terms of the BSD License, or alternatively under the terms of the Apache License, Version 2.0. Copyright © 2011, John Engelhart.";
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"JSONKit", kInfoTitle, @"John Engelhart", kInfoAuthor, license, kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // iRate Setup
    //
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"iRate", kInfoTitle, @"Nick Lockwood", kInfoAuthor, @"https://github.com/nicklockwood/iRate", kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // Ubuntu Fonts Setup
    //
    license = [self loadFileFromBundle:@"Ubuntu-Font-LICENSE"];
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Ubuntu Font Family", kInfoTitle, @"Canonical Ltd", kInfoAuthor, license, kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // VisualPharm Icon
    //
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Icons8 (iOS 7 Set)", kInfoTitle, @"visualpharm", kInfoAuthor, @"http://www.visualpharm.com/", kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // Clouds Vector Icons
    //
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Clouds Vector Icons", kInfoTitle, @"Olof Brickarp", kInfoAuthor, @"http://www.yay.se/", kInfoLicense, nil];
    [_contributions addObject:info];
    //
    // Minimal Apple Device Icons
    //
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Minimal Apple Device Icons", kInfoTitle, @"Michael Reimer", kInfoAuthor, @"http://www.bestpsdfreebies.com/", kInfoLicense, nil];
    [_contributions addObject:info];
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDAboutViewController - didReceiveMemoryWarning was called");
#endif
    if (!self.isFirstResponder) {
        _closeButton = nil;
        _appVersionLabel = nil;
        _descriptionLabel = nil;
        _logoImageView = nil;
        _containerView = nil;
        _contributionListView = nil;
        [_contributions removeAllObjects];
        _contributions = nil;
        self.view = nil;
    }
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];
}


-(NSString *)loadFileFromBundle:(NSString *)resourceName
{
    NSString * path = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"txt"];
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

- (CGSize)size:(CGSize)constraint withText:(NSString *)text
{
    if (text) {
        NSDictionary * attributes = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14],
                                       NSParagraphStyleAttributeName: [NSMutableParagraphStyle defaultParagraphStyle] };
        
        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:text];
        [textStorage addAttributes:attributes range:NSMakeRange(0, [textStorage length])];
        
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:constraint];
        textContainer.lineFragmentPadding = 0;
        
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        
        return [layoutManager usedRectForTextContainer:textContainer].size;
    }
    
    return CGSizeZero;
}

#pragma mark - UITableViewDataSource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _contributions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identity = @"Cell";
    
    RDAboutTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil) {
        cell = [[RDAboutTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    cell.data = (NSMutableDictionary *)[_contributions objectAtIndex:indexPath.row];
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary * info = (NSMutableDictionary *)[_contributions objectAtIndex:indexPath.row];
    NSValue * value = [info valueForKey:kInfoLicenseTextSize];
    if (!value) {
        NSString * licenseString = [info objectForKey:kInfoLicense];
        CGSize licenseSize = [self size:CGSizeMake(tableView.bounds.size.width, 9999) withText:licenseString];
        value = [NSValue valueWithCGSize:licenseSize];
        [info setValue:value forKey:kInfoLicenseTextSize];
    }
    
    return [value CGSizeValue].height + 50;
}

- (IBAction)didClose
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
