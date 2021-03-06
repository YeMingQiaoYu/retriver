//
//  REAppListController.m
//  Retriver
//
//  Created by cyan on 2016/10/21.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "REAppListController.h"
#import "RETableView.h"
#import "REAppListCell.h"
#import "REAppInfoController.h"

typedef NS_ENUM(NSInteger, REListType) {
    REListTypeApp       = 0,
    REListTypePlugin
};

@interface REAppListController ()<
    UITableViewDelegate,
    UITableViewDataSource,
    UISearchResultsUpdating
>

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) NSArray *filtered;
@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) RETableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation REAppListController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.titleView = [[UISegmentedControl alloc] initWithItems:@[@"Apps", @"Plugins"]];
    
    self.segmentedControl.selectedSegmentIndex = REListTypeApp;
    [self.segmentedControl addTarget:self 
                              action:@selector(didSegementedControlValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
    
    self.tableView = [[RETableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    [self refresh];
}

- (UISegmentedControl *)segmentedControl {
    return (UISegmentedControl *)self.navigationItem.titleView;
}

- (void)didSegementedControlValueChanged:(UISegmentedControl *)sender {
    [self refresh];
    [self.tableView setContentOffset:CGPointMake(0, -64) animated:YES];
}

- (void)refresh {
    
    NSArray *apps = [REWorkspace installedApplications];
    NSArray *plugins = [REWorkspace installedPlugins];
    NSArray *data;
    
    [self.segmentedControl setTitle:[NSString stringWithFormat:@"Apps (%d)", (int)apps.count]
                  forSegmentAtIndex:REListTypeApp];
    [self.segmentedControl setTitle:[NSString stringWithFormat:@"Plugins (%d)", (int)plugins.count]
                  forSegmentAtIndex:REListTypePlugin];
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case REListTypeApp: data = apps; break;
        case REListTypePlugin: data = plugins; break;
        default: break;
    }
    
    self.apps = [data sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *name1 = [REWorkspace displayNameForApplication:obj1];
        NSString *name2 = [REWorkspace displayNameForApplication:obj2];
        return [name1 compare:name2];
    }];
    self.filtered = self.apps;
    
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filtered.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"REHomeCell";
    REAppListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[REAppListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [cell render:self.filtered[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    REAppInfoController *infoController = [[REAppInfoController alloc] initWithInfo:self.filtered[indexPath.row]];
    infoController.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    self.searchController.active = NO;
    [self.navigationController pushViewController:infoController animated:YES];
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text.lowercaseString;
    if (isBlankText(searchText)) {
        self.filtered = self.apps;
        [self.tableView reloadData];
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableArray *filtered = [NSMutableArray array];
            for (id app in self.apps) {
                NSString *name = [REWorkspace displayNameForApplication:app];
                if ([name.lowercaseString containsString:searchController.searchBar.text.lowercaseString]) {
                    [filtered addObject:app];
                }
            }
            self.filtered = filtered;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    }
}

@end
