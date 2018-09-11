package arm;

import iron.math.Vec4;
import iron.object.Object;
import iron.object.BoneAnimation;
import iron.system.Time;
import iron.system.Audio;
import iron.system.Input;
import armory.trait.physics.RigidBody;

class PlayerController extends iron.Trait {

#if (!arm_physics)
	public function new() { super(); }
#else
	
	var soundStep0:kha.Sound = null;
	var soundStep1:kha.Sound = null;

	var mouse:Mouse = null;
	var keyboard:Keyboard = null;
	var gamepad:Gamepad = null;

	var body:RigidBody;
	var anim:BoneAnimation;

	var moveX = 0.0;
	var moveY = 0.0;
	var stepTime = 0.0;
	var fireTime = 0.0;
	var speed = 1.0;
	var dir = new Vec4();
	var state = "idle";

	public function new() {
		super();
		notifyOnInit(init);
		notifyOnUpdate(update);
	}

	function init() {
		mouse = Input.getMouse();
		keyboard = Input.getKeyboard();
		gamepad = Input.getGamepad(0);

		body = object.getTrait(RigidBody);
		anim = findAnimation(object.getChild("Armature"));

		iron.data.Data.getSound("step0.wav", function(sound:kha.Sound) { soundStep0 = sound; });
		iron.data.Data.getSound("step1.wav", function(sound:kha.Sound) { soundStep1 = sound; });
	}

	function update() {
		moveX = moveY = 0.0;

		if (keyboard.down("w")) moveY = 1.0;
		if (keyboard.down("s")) moveY = -1.0;
		if (keyboard.down("a")) moveX = -1.0;
		if (keyboard.down("d")) moveX = 1.0;
		if (Math.abs(gamepad.leftStick.x) > 0.1) moveX = gamepad.leftStick.x;
		if (Math.abs(gamepad.leftStick.y) > 0.1) moveY = gamepad.leftStick.y;

		dir.set(0, 0, 0);
		if (moveX != 0.0) dir.add(object.transform.right().mult(moveX * speed * 5.0));
		if (moveY != 0.0) dir.add(object.transform.look().mult(moveY * speed * 5.0));

		updateBody();
	}

	function updateBody() {

		if (!body.ready) return;

		// Mouse control
		var mx = -(iron.App.w() / 2 - mouse.x) / iron.App.w();
		var my = (iron.App.h() / 2 - mouse.y) / iron.App.h();
		var mv = new Vec4(mx * 2, my * 2, 0.0);
		mv.normalize();
		object.children[0].transform.rot.fromTo(Vec4.yAxis(), mv);

		
		// Gamepad control
		// if (gamepad != null) {
		// 	if (Math.abs(gamepad.rightStick.x) > 0.7 || Math.abs(gamepad.rightStick.y) > 0.7) {
		// 		object.children[0].transform.rot.fromTo(Vec4.yAxis(), new Vec4(gamepad.rightStick.x, gamepad.rightStick.y, 0.0));
		// 	}
		// }
		
		body.syncTransform();

		// Animation
		if (moveX != 0.0 || moveY != 0.0) {
			if (state != "run") setState("run", 1.0);

			stepTime += Time.delta;
			if (stepTime > 0.3 / speed) {
				stepTime = 0;
				Audio.play(Std.random(2) == 0 ? soundStep0 : soundStep1);
			}
		}
		else if (state != "fire" || state != "idle") {
			if (mouse.down("left") || gamepad.down("r2") > 0.0) {
				fireTime = 0.0;
				if (state != "fire") setState("fire", 2.0);
			}
			else {
				if (state != "idle" && state == "run") setState("idle", 2.0);
				if (state != "idle" && state == "fire" && fireTime > 0.1) setState("idle", 2.0);
			}
		}

		if (state == "fire") fireTime += Time.delta;
		else fireTime = 0.0;

		body.activate();
		var linvel = body.getLinearVelocity();
		body.setLinearVelocity(dir.x, dir.y, linvel.z - 1.0); // Push down
		body.setAngularFactor(0, 0, 0); // Keep vertical
	}

	function setState(s:String, speed:Float) {
		state = s;
		anim.play(s, null, 0.2, speed);
	}

	static function findAnimation(o:Object):BoneAnimation {
		if (o.animation != null) return cast o.animation;
		for (c in o.children) {
			var co = findAnimation(c);
			if (co != null) return co;
		}
		return null;
	}
#end
}
