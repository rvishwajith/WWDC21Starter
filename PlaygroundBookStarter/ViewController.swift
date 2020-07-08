//
//  ViewController.swift
//  PlaygroundBookStarter
//
//  Created by Rohith Vishwajith on 6/25/20.
//  Copyright © 2020 Rohith Vishwajith. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func loadView() {
        
        let view = UIView()
        self.view = view
        
        let navController = UINavigationController(rootViewController: self)
        navController.isNavigationBarHidden = true
        UIApplication.shared.windows.first?.rootViewController = navController
        
        let loadingVC = LoadingViewController()
        navController.pushViewController(loadingVC, animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

class LoadingViewController: UIViewController
{
    override func loadView() {
        let view = UIView()
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        perform(#selector(changeView), with: nil, afterDelay: 1.0)
    }
    
    @objc func changeView()
    {
        let lcController = LocationChooserViewController()
        self.navigationController?.pushViewController(lcController, animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

class LocationChooserViewController: UIViewController
{
    let interfaceView = UIView()
    let earth = LocationChooserSceneView()
    
    let reef = ReefViewController()
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = UIColor.black
        self.view = view
        
        interfaceView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        interfaceView.layer.cornerRadius = 8
        
        view.addSubview(earth)
        view.addSubview(interfaceView)
        
        earth.setup()
    }
    
    override func viewDidLayoutSubviews() {
        
        let height = self.view.frame.height
        let width = self.view.frame.width
        let desiredHeight = CGFloat(180)
        
        let inset = CGFloat(10);
        
        earth.frame = CGRect(x: 0, y: 0, width: width, height: height - desiredHeight - inset * 2)
        interfaceView.frame = CGRect(x: inset, y: height - desiredHeight - inset, width: width - inset * 2, height: desiredHeight)
        
        self.navigationController?.pushViewController(reef, animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

class LocationChooserSceneView: SCNView
{
    var spheres: [SCNSphere] = []
    var nodes: [SCNNode] = []
    var continentCounter = 0
    
    var cameraNode = SCNNode()
    var camera = SCNCamera()
    var earthScene: SCNScene = SCNScene()
    
    func setup()
    {
        earthScene.rootNode.addChildNode(cameraNode)
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2.5)
        
        for index in 1...6 {
            
            let material = SCNMaterial()
            let fileLocation = "WWDC21/EarthTextures/EarthTexture\(index).png"
            let image = UIImage(named: fileLocation)!
            material.diffuse.contents = image
            
            let sphere = SCNSphere(radius: 1.0)
            sphere.segmentCount = 64
            sphere.materials = [material]
            //sphere.firstMaterial?.fillMode = .lines
            spheres.append(sphere)
        }
        
        for sphere in spheres
        {
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(0, 0, 0)
            nodes.append(node)
        }
        
        for node in nodes
        {
            earthScene.rootNode.addChildNode(node)
        }
        
        let rotationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(rotateEarth), userInfo: nil, repeats: true)
        rotationTimer.fire()
        
        for index in 0..<nodes.count
        {
            let scale = 1 + 0.2 * Double(index)
            let delay = 0.4 + 0.05 * Double(index)
            Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(scaleContinents), userInfo: nil, repeats: false)
            
            nodes[index].scale = SCNVector3(scale, scale, scale)
        }
        
        self.scene = earthScene
        self.rendersContinuously = true
        self.backgroundColor = UIColor.black
        self.allowsCameraControl = true
        self.cameraControlConfiguration.allowsTranslation = false
    }
    
    @objc func scaleContinents()
    {
        let action = SCNAction.scale(to: 1.0, duration: 0.5)
        nodes[continentCounter].runAction(action)
        continentCounter += 1
    }
    
    @objc func rotateEarth()
    {
        let action = SCNAction.rotateBy(x: 0, y: 0.05, z: 0, duration: 1.0)
        for node in nodes
        {
            node.runAction(action)
        }
    }
}

class ReefViewController: UIViewController
{
    let reefScene = ReefSceneView()
    
    override func loadView()
    {
        let view = UIView()
        view.addSubview(reefScene)
        reefScene.initialSetup()
        self.view = view
    }
    
    override func viewDidLoad()
    {
        
    }
    
    override func viewDidLayoutSubviews()
    {
        reefScene.frame = self.view.frame
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
}

class ReefSceneView: SCNView, SCNSceneRendererDelegate
{
    var cameraNode = SCNNode()
    var camera = SCNCamera()
    var newScene: SCNScene = SCNScene()
    
    var allCreatures: [Creature] = []
    var largeCreatures: [Creature] = []
    var allKelp: [Kelp] = []
    
    func initialSetup()
    {
        newScene.rootNode.addChildNode(cameraNode)
        cameraNode.camera = camera
        //camera.focalLength = 35.0
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)
        
        addGround()
        addLargeCreatures()
        addTags()
        addKelp()
        
        self.delegate = self
        self.scene = newScene
        self.rendersContinuously = true
        self.showsStatistics = true
        self.backgroundColor = UIColor.black
        self.allowsCameraControl = true
        self.autoenablesDefaultLighting = true
        //self.cameraControlConfiguration.allowsTranslation = false
    }
    
    func addGround()
    {
        let width = CGFloat(24);
        let floor = SCNBox(width: width, height: 1, length: width, chamferRadius: 0)
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(x: 0, y: 0, z: 0)
        newScene.rootNode.addChildNode(floorNode)
    }
    
    func addLargeCreatures()
    {
        /* Max default cubes: 150,000 */
        let numberOfLargeCreatures = 48
        
        /* Geometry intialization here */
        let geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        
        for _ in 0..<numberOfLargeCreatures
        {
            let node = SCNNode(geometry: geometry)
            let name = "Blacktip Shark"
            let scale = Float(1.0)
            let level = 3
            
            /* POSITION CALCULATION */
            
            /*
            let phi = Float.random(in: 0...(Float.pi * 2))
            let costheta = Float.random(in: -1...1)
            let u = Float.random(in: 0...1)*/
            
            //let theta = arc4random()
            let position = SCNVector3(x: Float(arc4random_uniform(18)) - 10, y: Float(arc4random_uniform(12)), z: Float(arc4random_uniform(18)) - 20)
            
            /* -------------------- */
            
            newScene.rootNode.addChildNode(node)
            let creature = Creature(node, position, name, level, scale)
            allCreatures.append(creature)
            largeCreatures.append(creature)
        }
        
        /* ignore this */
        /*
        for creature in largeCreatures
        {
            let moveForward = SCNAction.moveBy(x: 0, y: 0, z: 40, duration: 6)
            moveForward.timingMode = .easeInEaseOut;
            let moveBackward = moveForward.reversed()
            
            let sequence = SCNAction.sequence([moveForward, moveBackward])
            let loop = SCNAction.repeatForever(sequence)
            
            //creature.node.runAction(loop)
        }*/
    }
    
    /* The ticket number is a way of differentiating boids by checking a number rather than if the objects are equal */
    func addTags()
    {
        var ticket = 0
        for creature in allCreatures
        {
            creature.ticketNumber = ticket
            ticket += 1
        }
    }
    
    func addKelp()
    {
        let numberOfKelp = 0
        
        let geometry = SCNCylinder(radius: 0.05, height: 20)
        geometry.heightSegmentCount = 192
        geometry.radialSegmentCount = 20
        
        
        let material = SCNMaterial()
        var shaders = [SCNShaderModifierEntryPoint: String]()
        try! shaders[SCNShaderModifierEntryPoint.geometry] = String(contentsOfFile: Bundle.main.path(forResource: "WWDC21/Shaders/KelpVertex", ofType: "cpp")!, encoding: String.Encoding.utf8)
        material.shaderModifiers = shaders
        geometry.materials = [material]
        
        for _ in 0..<numberOfKelp
        {
            let node = SCNNode(geometry: geometry)
            let position = SCNVector3(x: Float(arc4random_uniform(24)) - 12, y: 9.6, z: Float(arc4random_uniform(12)) - 12)
            
            newScene.rootNode.addChildNode(node)
            let kelp = Kelp(node, position)
            allKelp.append(kelp)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        calculateLargeBoids()
        //print(largeCreatures[0].velocity)
        checkKelpCollisions()
    }
    
    func checkKelpCollisions()
    {
        for kelp in allKelp
        {
            var yHitpoints: [Float] = []
            var xPushes: [Float] = []
            var zPushes: [Float] = []
            var radii: [Float] = []
            
            for creature in largeCreatures
            {
                if(VectorCalc.Distance3D(kelp.node.position, creature.node.position) > 4)
                {
                    let creatureY = creature.node.position.y
                    let kelpY = kelp.node.position.y
                    let offset = creatureY - kelpY
                    let xPush = creature.node.position.x - kelp.node.position.x
                    let zPush = creature.node.position.z - kelp.node.position.z
                    
                    yHitpoints.append(offset)
                    xPushes.append(xPush)
                    zPushes.append(zPush)
                    radii.append(1)
                }
            }
            
            let vertexShader = kelp.node.geometry!.firstMaterial!.shaderModifiers!
            //print(vertexShader.keys)
        }
    }
    
    /*
     PROCEDURE move_all_boids_to_new_positions()

         Vector v1, v2, v3
         Boid b

         FOR EACH BOID b
             v1 = rule1(b)
             v2 = rule2(b)
             v3 = rule3(b)

             b.velocity = b.velocity + v1 + v2 + v3
             b.position = b.position + b.velocity
         END

     END PROCEDURE
     */
    func calculateLargeBoids()
    {
        for creature in largeCreatures
        {
            let rule1 = VectorCalc.normalizeVector(largeBoidsRule1(creature, Float(largeCreatures.count)))
            let rule2 = VectorCalc.normalizeVector(largeBoidsRule2(creature))
            let rule3 = VectorCalc.normalizeVector(largeBoidsRule3(creature, Double(largeCreatures.count)))
            
            /*
            if(creature.ticketNumber == 10)
            {
                print("Rule 1: \(rule1)")
                print("Rule 2: \(rule2)")
                print("Rule 3: \(rule3)")
            }*/
            
            creature.velocity = VectorCalc.addVectors(
                VectorCalc.addVectors(creature.velocity, rule1),
                VectorCalc.addVectors(rule2, rule3))
            creature.velocity = VectorCalc.multiplyVector(creature.velocity, 0.1)
             
            creature.node.position = VectorCalc.addVectors(creature.node.position, creature.velocity)
        }
    }
    
    /*
     PROCEDURE rule1(boid bJ)

         Vector pcJ

         FOR EACH BOID b
             IF b != bJ THEN
                 pcJ = pcJ + b.position
             END IF
         END

         pcJ = pcJ / N-1

         RETURN (pcJ - bJ.position) / 100

     END PROCEDURE
     */
    func largeBoidsRule1(_ creature: Creature, _ count: Float) -> SCNVector3
    {
        var centerOfMass = SCNVector3(x: 0, y: 0, z: 0)
        let percentPush = Float(100)
        
        for creatures in largeCreatures
        {
            if(creatures.ticketNumber != creature.ticketNumber)
            {
                centerOfMass = VectorCalc.addVectors(centerOfMass, creatures.node.position)
            }
        }
        
        centerOfMass = VectorCalc.divideVector(centerOfMass, count - 1)
        return VectorCalc.divideVector(VectorCalc.subtractVectors(centerOfMass, creature.node.position), percentPush)
    }
    
    /*
     PROCEDURE rule2(boid bJ)

         Vector c = 0;

         FOR EACH BOID b
             IF b != bJ THEN
                 IF |b.position - bJ.position| < 100 THEN
                     c = c - (b.position - bJ.position)
                 END IF
             END IF
         END

         RETURN c
     END PROCEDURE
     */
    func largeBoidsRule2(_ creature: Creature) -> SCNVector3
    {
        var smallDistance = SCNVector3(x: 0, y: 0, z: 0)
        let distanceRadius = Double(12)
        
        for creatures in largeCreatures
        {
            if(creature.ticketNumber != creatures.ticketNumber)
            {
                if(VectorCalc.Distance3D(creatures.node.position, creature.node.position) < distanceRadius)
                {
                    smallDistance = VectorCalc.subtractVectors(
                        smallDistance,
                        VectorCalc.subtractVectors(creatures.node.position, creature.node.position))
                }
            }
        }
        return smallDistance
    }
    
    /*
     PROCEDURE rule3(boid bJ)

         Vector pvJ

         FOR EACH BOID b
             IF b != bJ THEN
                 pvJ = pvJ + b.velocity
             END IF
         END

         pvJ = pvJ / N-1

         RETURN (pvJ - bJ.velocity) / 8

     END PROCEDURE
     */
    func largeBoidsRule3(_ creature: Creature, _ count: Double) -> SCNVector3
    {
        let velocityMatchFactor = Float(8)
        var percievedVelocity = SCNVector3(0, 0, 0)
        
        for creatures in largeCreatures
        {
            if(creatures.ticketNumber != creature.ticketNumber)
            {
                percievedVelocity = VectorCalc.addVectors(percievedVelocity, creatures.velocity)
            }
        }
        
        percievedVelocity = VectorCalc.divideVector(percievedVelocity, Float(count - 1))
        
        return VectorCalc.divideVector(
            VectorCalc.subtractVectors(percievedVelocity, creature.velocity),
            velocityMatchFactor)
    }
}

class VectorCalc
{
    static func Distance3D(_ position1: SCNVector3, _ position2: SCNVector3) -> Double
    {
        return Double(sqrt(pow(abs(position1.x - position2.x), 2) + pow(abs(position1.x - position2.x), 2) + pow(abs(position1.x - position2.x), 2)))
    }
    
    static func addVectors(_ position1: SCNVector3, _ position2: SCNVector3) -> SCNVector3
    {
        let newVector3 = SCNVector3(
            x: position1.x + position2.x,
            y: position1.y + position2.y,
            z: position1.z + position2.z)
        return newVector3
    }
    
    static func subtractVectors(_ position1: SCNVector3, _ position2: SCNVector3) -> SCNVector3
    {
        let newVector3 = SCNVector3(
            x: position1.x - position2.x,
            y: position1.y - position2.y,
            z: position1.z - position2.z)
        return newVector3
    }
    
    static func divideVector(_ position: SCNVector3, _ divisionFactor: Float) -> SCNVector3
    {
        let newVector3 = SCNVector3(
            x: position.x/divisionFactor,
            y: position.y/divisionFactor,
            z: position.z/divisionFactor)
        return newVector3
    }
    
    static func multiplyVector(_ position: SCNVector3, _ multiplicationFactor: Float) -> SCNVector3
    {
        let newVector3 = SCNVector3(
            x: position.x * multiplicationFactor,
            y: position.y * multiplicationFactor,
            z: position.z * multiplicationFactor)
        return newVector3
    }
    
    static func normalizeVector(_ vector: SCNVector3) -> SCNVector3
    {
        let divisionFactor = max(abs(vector.x), max(abs(vector.y), abs(vector.z)))
        let x = vector.x/divisionFactor
        let y = vector.y/divisionFactor
        let z = vector.z/divisionFactor
        return SCNVector3(x, y, z)
    }
}

class Kelp
{
    var node: SCNNode!
    
    init(_ newNode: SCNNode, _ newPosition: SCNVector3)
    {
        node = newNode
        node.position = newPosition
    }
}

class Creature
{
    var node: SCNNode!
    var velocity: SCNVector3 = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
    var heirarchyLevel: Int!
    var name: String!
    var ticketNumber: Int!
    
    init(_ newNode: SCNNode, _ newPosition: SCNVector3, _ name: String, _ newLevel: Int, _ newScale: Float)
    {
        node = newNode
        node.position = newPosition
        heirarchyLevel = newLevel
        node.scale = SCNVector3(x: newScale, y: newScale, z: newScale)
        self.name = name
    }
}

extension SCNVector3 {
    
    static func +(left: SCNVector3, right: SCNVector3) -> SCNVector3
    {
        return SCNVector3(left.x + right.x,
                          left.y + right.y,
                          left.z + right.z)
    }
    
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3
    {
        return SCNVector3(left.x - right.x,
                          left.y - right.y,
                          left.z - right.z)
    }
}
