//
//  MTExpandableTableView.m
//  iGithub
//
//  Created by Oliver Letterer on 11.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "MTExpandableTableView.h"

@interface MTExpandableTableView ()

@property (nonatomic, retain) NSMutableDictionary *expandableSectionsDictionary;
@property (nonatomic, retain) NSMutableDictionary *showingSectionsDictionary;
@property (nonatomic, retain) NSMutableDictionary *downloadingSectionsDictionary;
@property (nonatomic, retain) NSMutableDictionary *animatingSectionsDictionary;

@property (nonatomic, retain) UIView *storedTableHeaderView;
@property (nonatomic, retain) UIView *storedTableFooterView;

- (void)downloadDataInSection:(NSInteger)section;
- (BOOL)isSectionAnimating:(NSInteger)section;
- (BOOL)isSectionDownloading:(NSInteger)section;
- (void)setSection:(NSInteger)section expandable:(BOOL)yesno;
- (void)setSection:(NSInteger)section expanded:(BOOL)yesno;
- (void)setSection:(NSInteger)section downloading:(BOOL)yesno;
- (void)setSection:(NSInteger)section animating:(BOOL)yesno;
@end


static UITableViewRowAnimation MTExpandableTableViewReloadAnimation = UITableViewRowAnimationFade;
static NSTimeInterval MTExpandableTableViewRowAnimationWait = 0.4;

@implementation MTExpandableTableView

@synthesize expandableSectionsDictionary=_expandableSectionsDictionary, showingSectionsDictionary=_showingSectionsDictionary, animatingSectionsDictionary=_animatingSectionsDictionary, downloadingSectionsDictionary=_downloadingSectionsDictionary, myDelegate=_myDelegate, myDataSource=_myDataSource;
@synthesize maximumRowCountToStillUseAnimationWhileExpanding=_maximumRowCountToStillUseAnimationWhileExpanding;
@synthesize onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty=_onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty;
@synthesize storedTableHeaderView=_storedTableHeaderView, storedTableFooterView=_storedTableFooterView;
@synthesize animationDuration = _animationDuration;
#pragma mark - setters and getters

- (id<UITableViewDelegate>)delegate {
	return [super delegate];
}

- (void)setDelegate:(id<MTExpandableTableViewDelegate>)delegate {
	_myDelegate = delegate;
	[super setDelegate:self];
}

- (id<UITableViewDataSource>)dataSource {
	return [super dataSource];
}

- (void)setDataSource:(id<MTExpandableTableViewDatasource>)dataSource {
	_myDataSource = dataSource;
	[super setDataSource:self];
}

- (void)setTableFooterView:(UIView *)tableFooterView {
	if (tableFooterView != _storedTableFooterView) {
		[super setTableFooterView:nil];
		_storedTableFooterView = tableFooterView;
        [self resetExpansionStates];
		[self reloadData];
	}
}

- (void)setTableHeaderView:(UIView *)tableHeaderView {
	if (tableHeaderView != _storedTableHeaderView) {
		[super setTableHeaderView:nil];
		_storedTableHeaderView = tableHeaderView;
        [self resetExpansionStates];
		[self reloadData];
	}
}

- (void)setOnlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty:(BOOL)onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty {
	if (_onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty != onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty) {
		_onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty = onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty;
        [self resetExpansionStates];
		[self reloadData];
	}
}

- (BOOL)canExpandSection:(NSInteger)section {
//    return [self.myDataSource tableView:self canExpandSection:section];
	return [[self.expandableSectionsDictionary objectForKey:[NSNumber numberWithInt:section] ] boolValue];
}

- (BOOL)isSectionExpanded:(NSInteger)section {
    NSNumber *key = [NSNumber numberWithInteger:section];
    NSNumber *yesno = [_showingSectionsDictionary objectForKey:key];
    return (yesno != nil)?[yesno boolValue]:NO;    
}

- (BOOL)isSectionAnimating:(NSInteger)section
{
    NSNumber *key = [NSNumber numberWithInteger:section];
    NSNumber *yesno = [_animatingSectionsDictionary objectForKey:key];
    return (yesno != nil)?[yesno boolValue]:NO;    
}

- (BOOL)isSectionDownloading:(NSInteger)section
{
    NSNumber *key = [NSNumber numberWithInteger:section];
    NSNumber *yesno = [_downloadingSectionsDictionary objectForKey:key];
    return (yesno != nil)?[yesno boolValue]:NO;
}

- (void)setSection:(NSInteger)section expandable:(BOOL)yesno
{
    NSNumber *key = [NSNumber numberWithInteger:section];
    [_expandableSectionsDictionary setObject:[NSNumber numberWithBool:yesno] forKey:key];
}

- (void)setSection:(NSInteger)section expanded:(BOOL)yesno
{
    NSNumber *key = [NSNumber numberWithInteger:section];
    [_showingSectionsDictionary setObject:[NSNumber numberWithBool:yesno] forKey:key];
}

- (void)setSection:(NSInteger)section downloading:(BOOL)yesno
{
    NSNumber *key = [NSNumber numberWithInteger:section];
    [_downloadingSectionsDictionary setObject:[NSNumber numberWithBool:yesno] forKey:key];
}

- (void)setSection:(NSInteger)section animating:(BOOL)yesno
{
    NSNumber *key = [NSNumber numberWithInteger:section];
    [_animatingSectionsDictionary setObject:[NSNumber numberWithBool:yesno] forKey:key];
}

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	if ((self = [super initWithFrame:frame style:style])) {
		self.maximumRowCountToStillUseAnimationWhileExpanding = NSIntegerMax;
		self.expandableSectionsDictionary = [NSMutableDictionary dictionary];
		self.showingSectionsDictionary = [NSMutableDictionary dictionary];
		self.downloadingSectionsDictionary = [NSMutableDictionary dictionary];
		self.animatingSectionsDictionary = [NSMutableDictionary dictionary];
        self.animationDuration = 0.25f;
	}
	return self;
}

#pragma mark - private methods

- (void)downloadDataInSection:(NSInteger)section {
    [self setSection:section downloading:YES];
	[self.myDelegate tableView:self downloadDataForExpandableSection:section];
	[self reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:section] ] 
				withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - instance methods

- (void)cancelDownloadInSection:(NSInteger)section {
    [self setSection:section downloading:NO];
	[self reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:section] ] 
				withRowAnimation:UITableViewRowAnimationNone];
}

- (void)expandSection:(NSInteger)section animated:(BOOL)animated {
	if ([self isSectionExpanded:section]) {
		// section is already showing, return
		return;
	}
	
	if ([self.myDataSource tableView:self needsToDownloadDataForExpandableSection:section]) {
		// data is still not ready to be displayed, return
		[self downloadDataInSection:section];
		return;
	}
    if ([self.myDelegate respondsToSelector:@selector(tableView:willExpandSection:)])
		[self.myDelegate tableView:self willExpandSection:section];

	[self setSection:section animating:YES];
	
	// remove the download state
	[self setSection:section downloading:NO];
    
    [self setSection:section expanded:YES];
    
	NSInteger newRowCount = [self.myDataSource tableView:self numberOfRowsInSection:section];

	// now do the animation magic to insert the new cells
	if (animated && newRowCount <= self.maximumRowCountToStillUseAnimationWhileExpanding) {
		[self beginUpdates];
		
		UITableViewCell<MTExpandingTableViewCell> *cell = (UITableViewCell<MTExpandingTableViewCell> *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
		[cell setExpansionStyle:MTExpansionStyleExpanded animated:YES];
		
		NSMutableArray *insertArray = [NSMutableArray array];
		for (int i = 1; i < newRowCount; i++) {
			[insertArray addObject:[NSIndexPath indexPathForRow:i inSection:section] ];
		}
		
		[self insertRowsAtIndexPaths:insertArray withRowAnimation:MTExpandableTableViewReloadAnimation];
		
		[self endUpdates];
	} else {
		[self reloadData];
	}
	
    [self setSection:section animating:NO];
	
	[self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] 
				atScrollPosition:UITableViewScrollPositionTop 
						animated:animated];
	
	// inform that we did scroll
	void(^animationBlock)(void) = ^(void) {
		[self scrollViewDidScroll:self];
	};
	
    [UIView animateWithDuration:animated?self.animationDuration:0.f 
                     animations:animationBlock 
                     completion:^(BOOL finished) {
    }];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, MTExpandableTableViewRowAnimationWait * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self.myDelegate respondsToSelector:@selector(tableView:didExpandSection:)])
            [self.myDelegate tableView:self didExpandSection:section];
    });
}

- (void)collapseSection:(NSInteger)section animated:(BOOL)animated {
	if (![self isSectionExpanded:section]) {
		// section is not showing, return
		return;
	}
    
    if ([self.myDelegate respondsToSelector:@selector(tableView:willCollapseSection:)])
        [self.myDelegate tableView:self willCollapseSection:section];
    
    [self setSection:section animating:YES];
    [self setSection:section expanded:NO];
    

	NSInteger newRowCount = [self.myDataSource tableView:self numberOfRowsInSection:section];

	// now do the animation magic to delete the new cells
	if (animated && newRowCount <= self.maximumRowCountToStillUseAnimationWhileExpanding) {
		[self beginUpdates];
		
		UITableViewCell<MTExpandingTableViewCell> *cell = (UITableViewCell<MTExpandingTableViewCell> *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
		[cell setExpansionStyle:MTExpansionStyleCollapsed animated:YES];
		
		NSMutableArray *deleteArray = [NSMutableArray array];
		for (int i = 1; i < newRowCount; i++) {
			[deleteArray addObject:[NSIndexPath indexPathForRow:i inSection:section] ];
		}
		
		[self deleteRowsAtIndexPaths:deleteArray withRowAnimation:MTExpandableTableViewReloadAnimation];
		
		[self endUpdates];
	} else {
		[self reloadData];
	}
	
    [self setSection:section animating:NO];
	
	[self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] 
				atScrollPosition:UITableViewScrollPositionTop 
						animated:animated];
	
	// inform that we did scroll
	void(^animationBlock)(void) = ^(void) {
		[self scrollViewDidScroll:self];
	};
	
    [UIView animateWithDuration:animated?self.animationDuration:0.f 
                     animations:animationBlock 
                     completion:^(BOOL finished) {
    }];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, MTExpandableTableViewRowAnimationWait * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self.myDelegate respondsToSelector:@selector(tableView:didCollapseSection:)])
            [self.myDelegate tableView:self didCollapseSection:section];
    });
}

- (void)toggleSection:(NSInteger)section {
	if ([self canExpandSection:section]) {
    // section is expandable
        // expand cell got clicked
        if ([self.myDataSource tableView:self needsToDownloadDataForExpandableSection:section]) {
            // we need to download some data first
            [self downloadDataInSection:section];
        } else {
            if ([self isSectionExpanded:section]) {
                [self collapseSection:section animated:YES];
            } else {
                [self expandSection:section animated:YES];
            }
        }
    }
}

- (void)resetExpansionStates {
	[self.expandableSectionsDictionary removeAllObjects];
	[self.showingSectionsDictionary removeAllObjects];
	[self.downloadingSectionsDictionary removeAllObjects];
    
    NSInteger numberOfSections = [self.myDataSource numberOfSectionsInTableView:self];
    
    for (NSInteger i=0; i < numberOfSections; i++)
    {
        if ([self.myDataSource tableView:self canExpandSection:i])
        {
            [self setSection:i expandable:YES];
            [self setSection:i downloading:[self.myDataSource tableView:self needsToDownloadDataForExpandableSection:i]];
            if ([self.myDataSource respondsToSelector:@selector(tableView:expandSection:)])
                [self setSection:i expanded:[self.myDataSource tableView:self expandSection:i]];
        }
        else
        {
            [self setSection:i expandable:NO];
        }
    }
}

#pragma mark - super implementation

- (void)reloadData {
    if (self.onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty) {
		if ([self numberOfSections] > 0) {
			if ([super tableFooterView] != self.storedTableFooterView) {
				[super setTableFooterView:self.storedTableFooterView];
			}
			if ([super tableHeaderView] != self.storedTableHeaderView) {
				[super setTableHeaderView:self.storedTableHeaderView];
			}
		}
	} else {
		if ([super tableFooterView] != self.storedTableFooterView) {
			[super setTableFooterView:self.storedTableFooterView];
		}
		if ([super tableHeaderView] != self.storedTableHeaderView) {
			[super setTableHeaderView:self.storedTableHeaderView];
		}
	}
	
	[super reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self isSectionAnimating:indexPath.section]) {
		if ([self.myDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPathWhileAnimatingSection:)]) {
			[self.myDelegate tableView:self willDisplayCell:cell forRowAtIndexPathWhileAnimatingSection:indexPath];
		}
	} else {
		if ([self.myDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
			[self.myDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
	}
	return tableView.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if ([self.myDelegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
		return [self.myDelegate tableView:tableView heightForHeaderInSection:section];
	}
	return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if ([self.myDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
		return [self.myDelegate tableView:tableView heightForFooterInSection:section];
	}
	return 0.0f;
}

// Section header & footer information. Views are preferred over title should you decide to provide both

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ([self.myDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
		return [self.myDelegate tableView:tableView viewForHeaderInSection:section];
	}
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if ([self.myDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
		return [self.myDelegate tableView:tableView viewForFooterInSection:section];
	}
	return nil;
}


// Accessories (disclosures). 

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:accessoryTypeForRowWithIndexPath:)]) {
		[self.myDelegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

// Selection

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView willSelectRowAtIndexPath:indexPath];
	}
	return indexPath;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView willDeselectRowAtIndexPath:indexPath];
	}
	return indexPath;
}
// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.myDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [self.myDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
		[self.myDelegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
	}
}


// Editing

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
	}
	return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:indexPath];
	}
	return NSLocalizedString(@"Delete", @"");
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView shouldIndentWhileEditingRowAtIndexPath:indexPath];
	}
	return YES;
}

- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)]) {
		[self.myDelegate tableView:tableView willBeginEditingRowAtIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:didEndEditingRowAtIndexPath:)]) {
		[self.myDelegate tableView:tableView didEndEditingRowAtIndexPath:indexPath];
	}
}

// Moving/reordering

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath 
	   toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
		return [self.myDelegate tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
	}
	return proposedDestinationIndexPath;
}

// Indentation

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:indentationLevelForRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
	}
	return 0;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDelegate respondsToSelector:@selector(tableView:shouldShowMenuForRowAtIndexPath:)]) {
		return [self.myDelegate tableView:tableView shouldShowMenuForRowAtIndexPath:indexPath];
	}
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if ([self.myDelegate respondsToSelector:@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:)]) {
		return [self.myDelegate tableView:tableView canPerformAction:action forRowAtIndexPath:indexPath withSender:sender];
	}
	return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if ([self.myDelegate respondsToSelector:@selector(tableView:performAction:forRowAtIndexPath:withSender:)]) {
		[self.myDelegate tableView:tableView performAction:action forRowAtIndexPath:indexPath withSender:sender];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
	if ([self.myDataSource tableView:self canExpandSection:section]) {
		if ([self.myDataSource tableView:tableView numberOfRowsInSection:section] == 0) {
			rows = 0;
		} else {
            [self setSection:section expandable:YES];
            
            if ([self isSectionExpanded:section]) {
                rows = [self.myDataSource tableView:tableView numberOfRowsInSection:section];
            } else {
                rows = 1;
            }
        }
	} else {
		[self setSection:section expandable:NO];
		// expanding is not supported
		rows = [self.myDataSource tableView:tableView numberOfRowsInSection:section];
	}
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![self canExpandSection:indexPath.section]) {
		return [self.myDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
	} else {
		// cell is expandable
		if (indexPath.row == 0) {
			UITableViewCell<MTExpandingTableViewCell> *cell = [self.myDataSource tableView:self expandingCellForSection:indexPath.section];
			if ([self isSectionDownloading:indexPath.section]) {
				[cell setLoading:YES];
			} else {
				[cell setLoading:NO];
				if ([self isSectionExpanded:indexPath.section]) {
					[cell setExpansionStyle:MTExpansionStyleExpanded animated:NO];
				} else {
					[cell setExpansionStyle:MTExpansionStyleCollapsed animated:NO];
				}
			}
			return cell;
		} else {
			return [self.myDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
		}
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([self.myDataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
		return [self.myDataSource numberOfSectionsInTableView:tableView];
	}
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if ([self.myDataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
		return [self.myDataSource tableView:tableView titleForHeaderInSection:section];
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if ([self.myDataSource respondsToSelector:@selector(tableView:titleForFooterInSection:)]) {
		return [self.myDataSource tableView:tableView titleForFooterInSection:section];
	}
	return nil;
}

// Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
		return [self.myDataSource tableView:tableView canEditRowAtIndexPath:indexPath];
	}
	return NO;
}

// Moving/reordering

//// Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) {
		return [self.myDataSource tableView:tableView canMoveRowAtIndexPath:indexPath];
	}
	return NO;
}

// Index

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	if ([self.myDataSource respondsToSelector:@selector(sectionIndexTitlesForTableView:)]) {
		return [self.myDataSource sectionIndexTitlesForTableView:tableView];
	}
	return nil;
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	if ([self.myDataSource respondsToSelector:@selector(tableView:sectionForSectionIndexTitle:atIndex:)]) {
		return [self.myDataSource tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
	}
	return 0;
}

// Data manipulation - insert and delete support

//// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.myDataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
		[self.myDataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
	}
}

// Data manipulation - reorder / moving support

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if ([self.myDataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
		[self.myDataSource tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
	}
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[self.myDelegate scrollViewDidScroll:scrollView];
	}
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
		[self.myDelegate scrollViewDidZoom:scrollView];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
		[self.myDelegate scrollViewWillBeginDragging:scrollView];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
		[self.myDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
		[self.myDelegate scrollViewWillBeginDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[self.myDelegate scrollViewDidEndDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
		[self.myDelegate scrollViewDidEndScrollingAnimation:scrollView];
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
		return [self.myDelegate viewForZoomingInScrollView:scrollView];
	}
	return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
		[self.myDelegate scrollViewWillBeginZooming:scrollView withView:view];
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
		[self.myDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
	}
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
		return [self.myDelegate scrollViewShouldScrollToTop:scrollView];
	}
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	if ([self.myDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
		[self.myDelegate scrollViewDidScrollToTop:scrollView];
	}
}

#pragma mark - Keyed Archiving

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeObject:_expandableSectionsDictionary forKey:@"expandableSectionsDictionary"];
	[encoder encodeObject:_showingSectionsDictionary forKey:@"showingSectionsDictionary"];
	[encoder encodeObject:_downloadingSectionsDictionary forKey:@"downloadingSectionsDictionary"];
	[encoder encodeObject:_animatingSectionsDictionary forKey:@"animatingSectionsDictionary"];
	[encoder encodeInteger:_maximumRowCountToStillUseAnimationWhileExpanding forKey:@"maximumRowCountToStillUseAnimationWhileExpanding"];
	[encoder encodeBool:_onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty forKey:@"onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty"];
	[encoder encodeObject:_storedTableHeaderView forKey:@"storedTableHeaderView"];
	[encoder encodeObject:_storedTableFooterView forKey:@"storedTableFooterView"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super initWithCoder:decoder])) {
		_expandableSectionsDictionary = [decoder decodeObjectForKey:@"expandableSectionsDictionary"];
		if (!_expandableSectionsDictionary)
			self.expandableSectionsDictionary = [NSMutableDictionary dictionary];
		_showingSectionsDictionary = [decoder decodeObjectForKey:@"showingSectionsDictionary"];
		if (!_showingSectionsDictionary)
			self.showingSectionsDictionary = [NSMutableDictionary dictionary];
		_downloadingSectionsDictionary = [decoder decodeObjectForKey:@"downloadingSectionsDictionary"];
		if (_downloadingSectionsDictionary)
			self.downloadingSectionsDictionary = [NSMutableDictionary dictionary];
		_animatingSectionsDictionary = [decoder decodeObjectForKey:@"animatingSectionsDictionary"];
		if (!_animatingSectionsDictionary)
			self.animatingSectionsDictionary = [NSMutableDictionary dictionary];
		_maximumRowCountToStillUseAnimationWhileExpanding = [decoder decodeIntegerForKey:@"maximumRowCountToStillUseAnimationWhileExpanding"];
		if (_maximumRowCountToStillUseAnimationWhileExpanding == 0)
			self.maximumRowCountToStillUseAnimationWhileExpanding = NSIntegerMax;
		_onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty = [decoder decodeBoolForKey:@"onlyDisplayHeaderAndFooterViewIfTableViewIsNotEmpty"];
		self.storedTableHeaderView = [decoder decodeObjectForKey:@"storedTableHeaderView"];
		self.storedTableFooterView = [decoder decodeObjectForKey:@"storedTableFooterView"];
	}
	return self;
}

@end
