// The MIT License
//
// Copyright (c) 2012 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#define GRMUSTACHE_VERSION_MAX_ALLOWED GRMUSTACHE_VERSION_6_0
#import "GRMustachePublicAPITest.h"

@interface GRMustacheFilterTestSupport: NSObject<GRMustacheFilter>
@end

@implementation GRMustacheFilterTestSupport

- (id)transformedValue:(id)object
{
    return object;
}

- (NSString *)test
{
    return @"failure";
}

@end

@interface GRMustacheFilterTest : GRMustachePublicAPITest
@end

@implementation GRMustacheFilterTest

- (void)testFilterCanChain
{
    id data = @{
        @"name" : @"Name",
        @"uppercase": [GRMustacheFilter filterWithBlock:^id(id value) {
            return [[value description] uppercaseString];
        }],
        @"prefix": [GRMustacheFilter filterWithBlock:^id(id value) {
            return [NSString stringWithFormat:@"prefix%@", [value description]];
        }],
    };
    
    NSString *templateString = @"<{{name}}> <{{prefix(name)}}> <{{uppercase(name)}}> <{{prefix(uppercase(name))}}> <{{uppercase(prefix(name))}}>";
    NSString *rendering = [[GRMustacheTemplate templateFromString:templateString error:NULL] renderObject:data];
    STAssertEqualObjects(rendering, @"<Name> <prefixName> <NAME> <prefixNAME> <PREFIXNAME>", nil);
}

- (void)testScopedValueAreExtractedOutOfAFilterExpression
{
    NSString *templateString = @"<{{f(object).name}}> {{#f(object)}}<{{name}}>{{/f(object)}}";
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:templateString error:NULL];
    
    {
        id data = @{
            @"object" : @{
                @"name": @"objectName",
            },
            @"name": @"rootName",
            @"f": [GRMustacheFilter filterWithBlock:^id(id value) {
                return value;
            }],
        };
        NSString *rendering = [template renderObject:data];
        STAssertEqualObjects(rendering, @"<objectName> <objectName>", nil);
    }
    
    {
        id data = @{
            @"object" : @{
                @"name": @"objectName",
            },
            @"name": @"rootName",
            @"f": [GRMustacheFilter filterWithBlock:^id(id value) {
                return @{ @"name": @"filterName" };
            }],
        };
        NSString *rendering = [template renderObject:data];
        STAssertEqualObjects(rendering, @"<filterName> <filterName>", nil);
    }
    
    {
        id data = @{
            @"object" : @{
                @"name": @"objectName",
            },
            @"name": @"rootName",
            @"f": [GRMustacheFilter filterWithBlock:^id(id value) {
                return @{};
            }],
        };
        NSString *rendering = [template renderObject:data];
        STAssertEqualObjects(rendering, @"<> <rootName>", nil);
    }
}

- (void)testFilteredSectionClosingTagCanHaveDifferentWhiteSpaceThanSectionOpeningTag
{
    NSString *templateString = @"{{#a(b)}}{{/ \t\na \t\n( \t\nb \t\n) \t\n}}";
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:templateString error:NULL];
    STAssertNotNil(template, nil);
}

- (void)testFilteredSectionClosingTagCanBeBlank
{
    NSString *templateString = @"<{{#uppercase(.)}}{{.}}{{/}}> <{{#uppercase(.)}}{{.}}{{/ }}>";
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:templateString error:NULL];
    STAssertNotNil(template, nil);
    NSString *rendering = [template renderObject:@"foo"];
    STAssertEqualObjects(rendering, @"<FOO> <FOO>", nil);
}

- (void)testFilteredSectionClosingTagCanNotBeInvalid
{
    NSString *templateString = @"<{{#uppercase(.)}}{{.}}{{/uppercase(.}}>";
    NSError *error;
    STAssertNil([GRMustacheTemplate templateFromString:templateString error:&error], nil);
    STAssertEquals(error.code, (NSInteger)GRMustacheErrorCodeParseError, nil);
}

- (void)testMissingFilterChainRaisesGRMustacheRenderingException
{
    id data = @{
        @"name": @"Name",
        @"replace": [GRMustacheFilter filterWithBlock:^id(id value) {
            return @"replace";
        }],
    };
    
    STAssertThrowsSpecificNamed([[GRMustacheTemplate templateFromString:@"<{{missing(missing)}}>" error:NULL] renderObject:data], NSException, GRMustacheRenderingException, nil);
    STAssertThrowsSpecificNamed([[GRMustacheTemplate templateFromString:@"<{{missing(name)}}>" error:NULL] renderObject:data], NSException, GRMustacheRenderingException, nil);
    STAssertThrowsSpecificNamed([[GRMustacheTemplate templateFromString:@"<{{replace(missing(name))}}>" error:NULL] renderObject:data], NSException, GRMustacheRenderingException, nil);
    STAssertThrowsSpecificNamed([[GRMustacheTemplate templateFromString:@"<{{missing(replace(name))}}>" error:NULL] renderObject:data], NSException, GRMustacheRenderingException, nil);
}

- (void)testNotAFilterRaisesGRMustacheRenderingException
{
    id data = @{
        @"name": @"Name",
        @"filter": @"filter",
    };
    
    NSString *templateString = @"<{{filter(name)}}>";
    STAssertThrowsSpecificNamed([[GRMustacheTemplate templateFromString:templateString error:NULL] renderObject:data], NSException, GRMustacheRenderingException, nil);
}

- (void)testFiltersDoNotEnterContextStack
{
    // TODO
    
//    id filter = [[[GRMustacheFilterTestSupport alloc] init] autorelease];
//    NSDictionary *data = [NSDictionary dictionaryWithObject:@"success" forKey:@"test"];
//    NSDictionary *filters = [NSDictionary dictionaryWithObject:filter forKey:@"filter"];
//    STAssertEqualObjects([filter valueForKey:@"test"], @"failure", nil);
//    NSString *templateString = @"<{{#filter}}failure{{/filter}}{{^filter}}success{{/filter}}><{{filter.test}}><{{filter(test)}}>";
//    NSString *rendering = [GRMustacheTemplate renderObject:data withFilters:filters fromString:templateString error:NULL];
//    STAssertEqualObjects(rendering, @"<success><><success>", nil);
}

- (void)testFilterArgumensDoNotEnterSectionContextStack
{
    id data = @{
        @"test": @"success",
        @"filtered": @{
            @"test": @"failure",
        },
        @"filter": [GRMustacheFilter filterWithBlock:^id(id value) {
            return @"filter";
        }],
    };
    NSString *templateString = @"{{#filter(filtered)}}<{{test}} instead of {{#filtered}}{{test}}{{/filtered}}>{{/filter(filtered)}}";
    NSString *rendering = [[GRMustacheTemplate templateFromString:templateString error:NULL] renderObject:data];
    STAssertEqualObjects(rendering, @"<success instead of failure>", nil);
}

- (void)testFilterNameSpace
{
    id data = @{
        @"x": @(0.5),
        @"math": @{
            @"double": [GRMustacheFilter filterWithBlock:^id(id value) {
                return @(2 * [(NSNumber *)value doubleValue]);
            }],
        },
    };
    NSString *rendering = [[GRMustacheTemplate templateFromString:@"{{ math.double(x) }}" error:NULL] renderObject:data];
    STAssertEqualObjects(rendering, @"1", nil);
}

- (void)testFiltersCanReturnFilters
{
    id data = @{
        @"prefix": @"prefix",
        @"value": @"value",
        @"f": [GRMustacheFilter filterWithBlock:^id(id value1) {
            return [GRMustacheFilter filterWithBlock:^id(id value2) {
                return [NSString stringWithFormat:@"%@%@", value1, value2];
            }];
        }],
    };
    NSString *rendering = [[GRMustacheTemplate templateFromString:@"{{f(prefix)(value)}}" error:NULL] renderObject:data];
    STAssertEqualObjects(rendering, @"prefixvalue", @"");
}

@end
