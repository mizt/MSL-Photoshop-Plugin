#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "PIFilter.h"

#define DLLExport extern "C"

class GPU {
    
    private:
        
        int width  = 1920;
        int height = 1080;
    
        id<MTLDevice> device;
        id<MTLLibrary> library;
    
        id<MTLTexture> texture[2];
    
        id<MTLCommandQueue> queue;
        id<MTLBuffer> resolution;
        
    public:
    
        unsigned int *data;
    
        GPU(int w, int h) {
            
            this->width  = w;
            this->height = h;
            
            this->device = MTLCreateSystemDefaultDevice();

            MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:NO];
            
            desc.usage = MTLTextureUsageShaderWrite;
            this->texture[1] = [this->device newTextureWithDescriptor:desc];

            desc.usage |= MTLTextureUsageShaderRead;
            this->texture[0] = [this->device newTextureWithDescriptor:desc];
                                     
            this->queue = [this->device newCommandQueue];
            
            this->resolution = [this->device newBufferWithLength:sizeof(float)*2 options:MTLResourceOptionCPUCacheModeDefault];
            float *res = (float *)[this->resolution contents];
            res[0] = this->width;
            res[1] = this->height;
            
            this->data = new unsigned int[this->width*this->height];
            
        }
    
        void exec() {
        
            NSBundle *bundle = [NSBundle bundleWithIdentifier:@"org.mizt.Metal"];
            NSString *path = [[bundle URLForResource:@"default" withExtension:@"metallib"] path];
                           
            NSFileManager *fileManager = [NSFileManager defaultManager];
               
            if([fileManager fileExistsAtPath:path]) {
                                
              dispatch_fd_t fd = open([path UTF8String],O_RDONLY);
              NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
              long size = [[attributes objectForKey:NSFileSize] integerValue];
                  
              dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
              dispatch_read(fd,size,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(dispatch_data_t d, int e) {
                  
                  NSError *err = nil;
                  this->library = [this->device newLibraryWithData:d error:&err];
                  //NSLog(@"%@",err);
                  close(fd);
                  dispatch_semaphore_signal(semaphore);

              });

              dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
                            
              id<MTLFunction> function = [library newFunctionWithName:@"processimage"];
              
              NSError *err = nil;
              id<MTLComputePipelineState> pipelineState = [this->device newComputePipelineStateWithFunction:function error:&err];
              //NSLog(@"%@",err);
              
              [this->texture[0] replaceRegion:MTLRegionMake2D(0,0,this->width,this->height) mipmapLevel:0 withBytes:this->data bytesPerRow:width<<2];
                                
              id<MTLCommandBuffer> commandBuffer = queue.commandBuffer;
              id<MTLComputeCommandEncoder> encoder = commandBuffer.computeCommandEncoder;
              [encoder setComputePipelineState:pipelineState];
              [encoder setTexture:this->texture[0] atIndex:0];
              [encoder setTexture:this->texture[1] atIndex:1];
              [encoder setBuffer:this->resolution offset:0 atIndex:0];
                
              MTLSize threadGroupSize = MTLSizeMake(8,8,1);
              MTLSize threadGroups = MTLSizeMake(
                std::ceil((float)(this->width /threadGroupSize.width )),
                std::ceil((float)(this->height/threadGroupSize.height)),
                1);
              
              [encoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
              [encoder endEncoding];
              [commandBuffer commit];
              [commandBuffer waitUntilCompleted];
                            
              [this->texture[1] getBytes:this->data bytesPerRow:this->width<<2 fromRegion:MTLRegionMake2D(0,0,this->width,this->height) mipmapLevel:0];
              
          }
        }
    
        ~GPU() {
            
            this->texture[0] = nil;
            this->texture[1] = nil;
            
            delete[] this->data;
        }
    
};

int16 StartProc(FilterRecord *filterRecord) {
    
    int16 width  = filterRecord->filterRect.right -filterRecord->filterRect.left;
    int16 height = filterRecord->filterRect.bottom-filterRecord->filterRect.top;
    int16 planes = filterRecord->planes;
    
    filterRecord->inLoPlane = 0;
    filterRecord->inHiPlane = planes - 1;
    filterRecord->outLoPlane = 0;
    filterRecord->outHiPlane = planes - 1;
    filterRecord->outRect = filterRecord->filterRect;
    filterRecord->inRect  = filterRecord->filterRect;
    
    int16 res = filterRecord->advanceState();
    if (res!=noErr) return res;
    
    NSLog(@"%d,%d,%d",width,height,planes);
        
    GPU *gpu = new GPU(width,height);
    
    for(int i=0; i<height; i++) {
        
        uint8 *src = (uint8 *)filterRecord->inData+(i*filterRecord->inRowBytes);
        
        for(int j=0; j<width; j++) {
            
            unsigned int pixel = 0xFF000000; 
            
            for(int ch=0; ch<planes; ch++) {
                switch(ch) {
                    case 0:
                        pixel |= (src[ch]); // red
                        break;
                    case 1:
                        pixel |= (src[ch])<<8; // green
                        break;
                    case 2:
                        pixel |= (src[ch])<<16; // blue
                        break;
                }
            }
            
            gpu->data[i*width+j] = pixel;
            src+=planes;
        }
    }
    
    gpu->exec();
    
    for(int i=0; i<height; i++) {
        uint8 *dst = (uint8 *)filterRecord->outData+(i*filterRecord->outRowBytes);
        for(int j=0; j<width; j++) {
            
            for(int ch=0; ch<planes; ch++) {
                
                unsigned int pixel = gpu->data[i*width+j];
                
                switch(ch) {
                    case 0:
                        dst[ch] = (pixel)&0xFF;
                        break;
                    case 1:
                        dst[ch] = (pixel>>8)&0xFF;
                        break;
                    case 2:
                        dst[ch] = (pixel>>16)&0xFF;
                        break;
                }
            }
            dst+=planes;
        }
    }
    
    memset(&(filterRecord->outRect),0,sizeof(Rect));
    memset(&(filterRecord->inRect),0,sizeof(Rect));
    
    delete gpu->data;
    
    return noErr;
}

DLLExport MACPASCAL void PluginMain(const int16 selector,FilterRecord *filterRecord,int32 *data,int16 *result) {
    switch (selector) {
        case filterSelectorStart:
            *result = StartProc(filterRecord);
            break;
    }
}
