#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "PIDefines.h"
#import "PIFilter.h"

int16 StartProc(FilterRecord *filterRecord)
{
    
    int16 width  = filterRecord->filterRect.right -filterRecord->filterRect.left;
    int16 height = filterRecord->filterRect.bottom-filterRecord->filterRect.top ;
    int16 planes = filterRecord->planes;
    
    filterRecord->inLoPlane = 0;
    filterRecord->inHiPlane = planes - 1;
    filterRecord->outLoPlane = 0;
    filterRecord->outHiPlane = planes - 1;
    filterRecord->outRect = filterRecord->filterRect;
    filterRecord->inRect  = filterRecord->filterRect;
    
    int16 res = filterRecord->advanceState();
    if (res!=noErr) return res;
    
    float *data = new float[width*height*4];
    
    for(int i=0; i<height; i++) {
        uint8 *src = (uint8 *)filterRecord->inData+(i*filterRecord->inRowBytes);
        for(int j=0; j<width; j++) {
            for(int ch=0; ch<planes; ch++) {
                switch(ch) {
                    case 0:
                    case 1:
                    case 2:
                        data[(i*width+j)*4+ch] = src[ch]/255.0;
                        break;
                }
            }
            src+=planes;
        }
    }
    
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"org.mizt.metal"];
    NSString *path = [[bundle URLForResource:@"default" withExtension:@"metallib"] path];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:path]) {
                
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        __block id<MTLLibrary> library;
        
        dispatch_fd_t fd = open([path UTF8String],O_RDONLY);
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
        long size = [[attributes objectForKey:NSFileSize] integerValue];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        dispatch_read(fd,size,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(dispatch_data_t d, int e) {
        
            library = [device newLibraryWithData:d error:nil];
            close(fd);
            dispatch_semaphore_signal(semaphore);

        });

        dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);

        id<MTLFunction> function = [library newFunctionWithName:@"processimage"];
        
        id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:function error:nil];
        
        id<MTLCommandQueue> queue = [device newCommandQueue];
        
        MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA32Float width:width height:height mipmapped:NO];
        descriptor.usage = MTLTextureUsageShaderWrite|MTLTextureUsageShaderRead;
        
        id<MTLTexture> texture[2] = {
            [device newTextureWithDescriptor:descriptor],
            [device newTextureWithDescriptor:descriptor]
        };
        
        [texture[0] replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:data bytesPerRow:width<<4];
        
        id<MTLCommandBuffer> commandBuffer = queue.commandBuffer;
        id<MTLComputeCommandEncoder> encoder = commandBuffer.computeCommandEncoder;
        [encoder setComputePipelineState:pipelineState];
        [encoder setTexture:texture[0] atIndex:0];
        [encoder setTexture:texture[1] atIndex:1];
        
        MTLSize threadGroupSize = MTLSizeMake(16,8,1);
        MTLSize threadGroups = MTLSizeMake(texture[1].width/threadGroupSize.width,texture[1].height/threadGroupSize.height,1);
        
        [encoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
        [encoder endEncoding];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        
        [texture[1] getBytes:data bytesPerRow:width<<4 fromRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0];
        
        texture[0] = nil;
        texture[1] = nil;
    }
    
    for(int i=0; i<height; i++) {
        uint8 *dst = (uint8 *)filterRecord->outData+(i*filterRecord->outRowBytes);
        for(int j=0; j<width; j++) {
            for(int ch=0; ch<planes; ch++) {
                switch(ch) {
                    case 0:
                    case 1:
                    case 2:
                        dst[ch] = data[(i*width+j)*4+ch]*255.0;
                        break;
                }
            }
            dst+=planes;
        }
    }
    
    memset(&(filterRecord->outRect),0,sizeof(Rect));
    memset(&(filterRecord->inRect),0,sizeof(Rect));
    
    delete[] data;
    
    return noErr;
}

DLLExport MACPASCAL void PluginMain(const int16 selector,FilterRecord *filterRecord,int32 *data,int16 *result)
{
    switch (selector) {
        case filterSelectorStart:
            *result = StartProc(filterRecord);
            break;
    }
}