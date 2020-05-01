//
//  ViewController.swift
//  ARShots
//
//  Created by Павел on 15.04.2020.
//  Copyright © 2020 Павел. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate  {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    var score = 0
    var hoopAdded = false
    var isBallBeginContactWithRim = false
    var isBallEndContactWithRim = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let node = SCNNode()
        let geometry = SCNPlane(width:
           CGFloat(planeAnchor.extent.x), height:
           CGFloat(planeAnchor.extent.z))
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.opacity = 0.25
        node.name = "wall"
        print("wall2")
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node:
       SCNNode, for anchor: ARAnchor) {
        if !hoopAdded{
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
    
        let wall = createWall(planeAnchor: planeAnchor)
        node.addChildNode(wall)
        
        print("wall")
    }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node:
       SCNNode, for anchor: ARAnchor) {
        if !hoopAdded{
        guard let planeAnchor = anchor as? ARPlaneAnchor
            else { return }
        
        for node in node.childNodes{
            node.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            if let plane = node.geometry as? SCNPlane{
                plane.width =  CGFloat(planeAnchor.extent.x)
                plane.height = CGFloat(planeAnchor.extent.z)
                print("Update")
            }
        }
    }
    }
    
    @IBAction func screenTaped(_ sender: UISwipeGestureRecognizer) {
       if !hoopAdded{
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(touchLocation, types:
            [.estimatedVerticalPlane, .estimatedHorizontalPlane])
    
        if !hitTestResult.isEmpty {
            addHoop(hitTestResult: hitTestResult.last!)
            
            hoopAdded = true
            
        }
        } else {
        createBasketBall()
        }
    }
    
    
    func horizontalAction (node: SCNNode, planePosition: simd_float4, top: SCNNode, bottom: SCNNode)->SCNNode{
        
        
        let leftAction = SCNAction.move(by: SCNVector3(x:node.position.x-3, y: node.position.y, z:node.position.z), duration: 2)
        let leftAction2 = SCNAction.move(by: SCNVector3(x:node.position.x-6, y: node.position.y, z:node.position.z), duration: 4)
        let rightAction = SCNAction.move(to: SCNVector3(x:node.position.x+3, y:node.position.y, z:node.position.z), duration: 2)
        let rightAction2 = SCNAction.move(to: SCNVector3(x:node.position.x+6, y:node.position.y, z:node.position.z), duration: 4)
        let upAction = SCNAction.move(to: SCNVector3(x:node.position.x, y:node.position.y+3, z:node.position.z), duration: 2)
        let downAction = SCNAction.move(to: SCNVector3(x:node.position.x, y:node.position.y-6, z:node.position.z), duration: 4)
       
        let upright = SCNAction.move(by: SCNVector3(x:node.position.x+1, y:node.position.y+1, z:node.position.z), duration: 2)
        let downright = SCNAction.move(to: SCNVector3(x:node.position.x+1, y:node.position.y-1, z:node.position.z), duration: 2)
        let downLeft = SCNAction.move(by: SCNVector3(x:node.position.x-1, y:node.position.y-1, z:node.position.z), duration: 2)
        let upLeft = SCNAction.move(to: SCNVector3(x:node.position.x-1, y:node.position.y+1, z:node.position.z), duration: 2)
        
        let returnAction = SCNAction.move(to: SCNVector3(x:node.position.x, y:node.position.y, z:node.position.z), duration: 2)
        
        let actionSequence = SCNAction.sequence([leftAction , rightAction2, returnAction])
        let actionSequence2 = SCNAction.sequence([rightAction , leftAction2, returnAction])
        let actionSequence3 = SCNAction.sequence([upright, downright , downLeft , upLeft, returnAction])
        let actionSequence4 = SCNAction.sequence([upLeft, downLeft , downright, upright, returnAction])
        let actionSequence5 = SCNAction.sequence([upAction, downAction, returnAction])
        let actionSequence6 = SCNAction.sequence([downAction, upAction, returnAction])
        let actionArray = [actionSequence, actionSequence2, actionSequence3, actionSequence4, actionSequence5, actionSequence6]
        
        let actionSequenceArray = SCNAction.sequence(actionArray.shuffled())
        let repeatAction = SCNAction.repeatForever(actionSequenceArray)
        
        while true{
                node.runAction(repeatAction)
                
                return node
        }
    }

}

struct ObjectCollisionCategory: OptionSet {
    let rawValue: Int
    
    static let none = ObjectCollisionCategory(rawValue: 0)
    static let topPlane = ObjectCollisionCategory(rawValue: 1)
    static let bottomPlane = ObjectCollisionCategory(rawValue: 4)
    static let ball = ObjectCollisionCategory(rawValue: 3 )
}

extension ViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.name == "Ball" && contact.nodeB.name == "Top plane" && !isBallBeginContactWithRim{
            isBallBeginContactWithRim = true
            isBallEndContactWithRim = false
            print(Date(), #function, "\(contact.nodeA.name!) begin contact with \(contact.nodeB.name!)")
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if isBallBeginContactWithRim && !isBallEndContactWithRim{
        if contact.nodeA.name == "Ball" && contact.nodeB.name == "Bottom plane"{
            isBallEndContactWithRim = true
            score += 1
            print(Date(), #function, "\(contact.nodeA.name!) end contact with \(contact.nodeB.name!)")
            DispatchQueue.main.async {
                self.scoreLabel.text = "Score: \(self.score)"
            }
            isBallBeginContactWithRim = false
        }
      }
    }
    
}

extension ViewController {
   func addHoop(hitTestResult: ARHitTestResult){
        
        let hoopScene = SCNScene(named: "art.scnassets/hoop.scn")
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else {
            return
        }
        
        let planePosition = hitTestResult.worldTransform.columns.3
       //hoopNode.position = SCNVector3(planePosition.x, planePosition.y, planePosition.z)
        
        
       /*hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node:hoopNode, options:
        [SCNPhysicsShape.Option.type:
        SCNPhysicsShape.ShapeType.concavePolyhedron]))*/
                
        
        var node = SCNNode()
        var nodeArray = hoopScene!.rootNode.childNodes
        for childNode in nodeArray {
          node.addChildNode(childNode as SCNNode)
          node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type:
            SCNPhysicsShape.ShapeType.concavePolyhedron]))
        }
    
    guard let topPlane = node.childNode(withName: "Top plane", recursively: true) else {print("f"); return}
    guard let bottomPlane = node.childNode(withName: "Bottom plane", recursively: true) else {print("f"); return}
    
    topPlane.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
    bottomPlane.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
     
    topPlane.physicsBody?.categoryBitMask = ObjectCollisionCategory.topPlane.rawValue
      topPlane.physicsBody?.collisionBitMask = ObjectCollisionCategory.none.rawValue
      topPlane.physicsBody?.contactTestBitMask = ObjectCollisionCategory.ball.rawValue
      
      bottomPlane.physicsBody?.categoryBitMask = ObjectCollisionCategory.bottomPlane.rawValue
      bottomPlane.physicsBody?.collisionBitMask = ObjectCollisionCategory.none.rawValue
      bottomPlane.physicsBody?.contactTestBitMask = ObjectCollisionCategory.ball.rawValue
       
      node.position = SCNVector3(planePosition.x, planePosition.y, planePosition.z)
      
      
    node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type:
        SCNPhysicsShape.ShapeType.concavePolyhedron]))
       
        //topPlane.position = SCNVector3(node.position.x, node.position.y-0.368, node.position.z+0.711)
        //bottomPlane.position = SCNVector3(node.position.x, node.position.y-0.535, node.position.z+0.728)

            
        hoopAdded = true
        sceneView.scene.rootNode.enumerateHierarchy { node, _ in
            if node.name == "wall" {
                node.removeFromParentNode()
            }
        }
        //sceneView.scene.rootNode.addChildNode(topPlane)
        //sceneView.scene.rootNode.addChildNode(bottomPlane)
        //sceneView.scene.rootNode.addChildNode(hoopNode)
        sceneView.scene.rootNode.addChildNode(node)
        horizontalAction(node: node, planePosition: planePosition, top: topPlane, bottom: bottomPlane)
    }
    
    func createBasketBall(){
        guard let currentFrame = sceneView.session.currentFrame else {return
        }
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named:"basketballSkin.png")
        
        let cameraTransform = SCNMatrix4(currentFrame.camera.transform)
        ball.transform = cameraTransform
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node:ball,
        options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        ball.physicsBody = physicsBody
        let power = Float(10.0)
        let force = SCNVector3(-cameraTransform.m31*power, -cameraTransform.m32*power, -cameraTransform.m33*power)
        ball.physicsBody?.applyForce(force, asImpulse: true)
        ball.name = "Ball"
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
}
