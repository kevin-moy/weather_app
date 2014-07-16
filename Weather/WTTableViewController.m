//
//  WTTableViewController.m
//  Weather
//
//  Created by Scott on 26/01/2013.
//  Updated by Joshua Greene 16/12/2013.
//
//  Copyright (c) 2013 Scott Sherwood. All rights reserved.
//

#import "WTTableViewController.h"
#import "WeatherAnimationViewController.h"
#import "NSDictionary+weather.h"
#import "NSDictionary+weather_package.h"
#import "UIImageView+AFNetworking.h"

static NSString * const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

@interface WTTableViewController ()

@property(nonatomic, strong) NSMutableDictionary *currentDictionary;
@property(nonatomic, strong) NSMutableDictionary *xmlWeather;
@property(nonatomic, strong) NSString *elementName;
@property(nonatomic, strong) NSMutableString *outstring;
@property(strong) NSDictionary *weather;

@end

@implementation WTTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"WeatherDetailSegue"]){
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        WeatherAnimationViewController *wac = (WeatherAnimationViewController *)segue.destinationViewController;
        
        NSDictionary *w;
        switch (indexPath.section) {
            case 0: {
                w = self.weather.currentCondition;
                break;
            }
            case 1: {
                w = [self.weather upcomingWeather][indexPath.row];
                break;
            }
            default: {
                break;
            }
        }
        wac.weatherDictionary = w;
    }
}

#pragma mark - Actions

- (IBAction)clear:(id)sender
{
    self.title = @"";
    self.weather = nil;
    [self.tableView reloadData];
}

//Create network operation that downloads and parses its response.
- (IBAction)jsonTapped:(id)sender
{
    
    //Create string representing full url from base URl -> create NSURL object, -> make NSURLRequest
    
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=json", BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //Tell that response should be read as JSON by setting responseSerializer as property of default JSON seralizer. AFNetworking takes care of parsing JSON to you
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        
        //JSON serializer parses received data and returns a dictionary in responseObject variable, stored in weather property
        self.weather = (NSDictionary *)responseObject;
        self.title = @"JSON Retrieved";
        [self.tableView reloadData];
    }
     
    //Display error message if something goes wrong ex. networking not available
     
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error receiving message" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        [alertView show];
    }];
    //Must tell operation to start of nothing will happen
    [operation start];
}

- (IBAction)plistTapped:(id)sender
{
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=plist", BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    // Set responseSerializer
    
    operation.responseSerializer = [AFPropertyListResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        self.weather = (NSDictionary *)responseObject;
        self.title = @"PLIST retrieved";
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error retrieving weather" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        
        [alertView show];
    }];
    
    [operation start];
}

- (IBAction)xmlTapped:(id)sender
{
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=xml", BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
      
        NSXMLParser *XMLParser = (NSXMLParser *)responseObject;
        [XMLParser setShouldProcessNamespaces:YES];
        
        XMLParser.delegate = self;
        [XMLParser parse];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error retrieving weather" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        
        [alertView show];
    }];
    [operation start];
}

//Create and display an action sheet asking user to choose between GET and POST
- (IBAction)clientTapped:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"AFHTTPSessionManager" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"HTTP GET", @"HTTP POST", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)apiTapped:(id)sender
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

//Display  current and upcoming weather on table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.weather) {
        return 0;
    }
    switch (section)  {
        case 0: {
            return 1;
        }
        case 1: {
            NSArray *upcomingWeather = [self.weather upcomingWeather];
            return [upcomingWeather count];
        }
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WeatherCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *daysWeather = nil;
    
    //First section shows current weather, second section shows upcoming weather
    switch (indexPath.section) {
        case 0: {
            daysWeather = [self.weather currentCondition];
            break;
        }
            
        case 1: {
            NSArray *upcomingWeather = [self.weather upcomingWeather];
            daysWeather = upcomingWeather[indexPath.row];
            break;
        }
            
        default:
            break;
    }
    
    cell.textLabel.text = [daysWeather weatherDescription];
    
    NSURL *url = [NSURL URLWithString:daysWeather.weatherIconURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
    
    __weak UITableViewCell *weakCell = cell;
    
    [cell.imageView setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        weakCell.imageView.image = image;
        [weakCell setNeedsLayout];
        
    } failure:nil];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
}

//Calls when first starts parsing and holds XML data in new dictionary

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.xmlWeather = [NSMutableDictionary dictionary];
}
//New element tag, set current dicgionaty to new dictionary if new weather forecast
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.elementName = qName;
    
    if([qName isEqualToString:@"current_condition"] ||
       [qName isEqualToString:@"weather"] ||
       [qName isEqualToString:@"request"]) {
        self.currentDictionary = [NSMutableDictionary dictionary];
    }
    
    self.outstring = [NSMutableString string];
}

// When new character on XML element
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!self.elementName)
        return;
    
    [self.outstring appendFormat:@"%@", string];
}
// When end element tag is encountered
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // add current weather to xml dictionary
    if ([qName isEqualToString:@"current_condition"] ||
        [qName isEqualToString:@"request"]) {
        self.xmlWeather[qName] = @[self.currentDictionary];
        self.currentDictionary = nil;
    }
    // Add weather information for subsequent days
    else if ([qName isEqualToString:@"weather"]) {
        
        // Initialize the list of weather items if it doesn't exist
        NSMutableArray *array = self.xmlWeather[@"weather"] ?: [NSMutableArray array];
        
        // Add the current weather object
        [array addObject:self.currentDictionary];
        
        // Set the new array to the "weather" key on xmlWeather dictionary
        self.xmlWeather[@"weather"] = array;
        
        self.currentDictionary = nil;
    }
    else if ([qName isEqualToString:@"value"]) {
        // Ignore value tags, they only appear in the two conditions below
    }
    // Desc and IConUrl boxed inside array before stored to patch JSON and plist
    else if ([qName isEqualToString:@"weatherDesc"] ||
             [qName isEqualToString:@"weatherIconUrl"]) {
        NSDictionary *dictionary = @{@"value": self.outstring};
        NSArray *array = @[dictionary];
        self.currentDictionary[qName] = array;
    }
    // All elements stored as is
    else if (qName) {
        self.currentDictionary[qName] = self.outstring;
    }
    
	self.elementName = nil;
}

//At end of document, dictionary complete
- (void) parserDidEndDocument:(NSXMLParser *)parser
{
    self.weather = @{@"data": self.xmlWeather};
    self.title = @"XML Retrieved";
    [self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        // User pressed cancel -- abort
        return;
    }
    
    // Set up baseURL and dictionary of parameters
    NSURL *baseURL = [NSURL URLWithString:BaseURLString];
    NSDictionary *parameters = @{@"format": @"json"};
    
    // Set responseSeralizer to default JSON Serializer
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // if GET, get GET method from manager and pass parameters
    if (buttonIndex == 0) {
        [manager GET:@"weather.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            self.weather = responseObject;
            self.title = @"HTTP GET";
            [self.tableView reloadData];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }];
    }
    
    // if POST
    else if (buttonIndex == 1) {
        [manager POST:@"weather.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            self.weather = responseObject;
            self.title = @"HTTP POST";
            [self.tableView reloadData];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }];
    }
}
@end