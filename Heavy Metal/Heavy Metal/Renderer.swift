//
//  Renderer.swift
//  Heavy Metal
//
//  Created by SAFT on 25/07/23.
//

import Foundation
import Metal
import MetalKit

class Renderer : NSObject, MTKViewDelegate {
    
    // Create our custom rendering pipeline, which loads shaders using `device`, and outputs to the format of `metalKitView`
    class func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws -> MTLRenderPipelineState {
        // Create a new pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        // Setup the shaders in the pipeline
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        // Setup the output pixel format to match the pixel format of the metal kit view
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        // Compile the configured pipeline descriptor to a pipeline state object
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
 
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState
    var vertexBuffer: MTLBuffer
    let fragmentUniformsBuffer: MTLBuffer

    // This keeps track of the system time of the last render
    var lastRenderTime: CFTimeInterval? = nil
    // This is the current time in our app, starting at 0, in units of seconds
    var currentTime: Double = 0
    
    let gpuLock = DispatchSemaphore(value: 1)
    
    var vertexCount = 0;


    // This is the initializer for the Renderer class.
    // We will need access to the mtkView later, so we add it as a parameter here.
    init?(mtkView: MTKView) {
        device = mtkView.device!
        commandQueue = device.makeCommandQueue()!
        
        // Create the Render Pipeline
        do {
            pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        // Create our vertex data
        var vertices:[Vertex] = []
        
        for i in 0...1023 {
            let y:Float = ((Float(i) * 2.0) / 1024.0) - 1.0
            
            for j in 0...1023 {
                let x:Float = ((Float(j) * 2.0) / 1024.0) - 1.0
                vertices.append(Vertex(color: [0, 0, 0, 1], pos: [x, y]))
            }
        }
        
        vertexCount = vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        
        // Create our uniform buffer, and fill it with an initial brightness of 1.0
        var initialFragmentUniforms = FragmentUniforms(timestamp: 1.0)
        fragmentUniformsBuffer = device.makeBuffer(bytes: &initialFragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, options: [])!
        
 
    }

    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
    func draw(in view: MTKView) {
        gpuLock.wait()

        // Compute dt
        let systemTime = CACurrentMediaTime()
        let timeDifference = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
        // Save this system time
        lastRenderTime = systemTime

        // Update state
        update(st: systemTime, dt: timeDifference)
        
        // Get an available command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // Get the default MTLRenderPassDescriptor from the MTKView argument
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        // Change default settings. For example, we change the clear color from black to red.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        // We compile renderPassDescriptor to a MTLRenderCommandEncoder.
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var timestamp: Float = Float(systemTime)
        let vertexBuffer2: MTLBuffer = device.makeBuffer(bytes: &timestamp, length: MemoryLayout<Float>.stride, options: [])!

        // What vertex buffer data to use
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer2, offset: 0, index: 1)

        // Bind the fragment uniforms
        renderEncoder.setFragmentBuffer(fragmentUniformsBuffer, offset: 0, index: 0)

        // And what to draw
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)

        // This finalizes the encoding of drawing commands.
        renderEncoder.endEncoding()
        
        // Tell Metal to send the rendering result to the MTKView when rendering completes
        commandBuffer.present(view.currentDrawable!)
        
        commandBuffer.addCompletedHandler { _ in
            self.gpuLock.signal()
        }

        // Finally, send the encoded command buffer to the GPU.
        commandBuffer.commit()
    }

    // mtkView will automatically call this function
    // whenever the size of the view changes (such as resizing the window).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
    
    func update(st: CFTimeInterval, dt: CFTimeInterval) {
        let ptr = fragmentUniformsBuffer.contents().bindMemory(to: FragmentUniforms.self, capacity: 1)
        //ptr.pointee.timestamp = Float(0.5 * cos(currentTime) + 0.5)
        ptr.pointee.timestamp = Float(st)
        currentTime += dt
    }
    


}



