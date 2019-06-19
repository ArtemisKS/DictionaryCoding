# DictionaryCoding
Grand way to decode/encode dictionary using codable technology (as in JSON Codable), implemented by a London Studio Elegant Chaos
_**[Link to the site](https://elegantchaos.com/2018/02/21/decoding-dictionaries-in-swift.html)**_

## About & stuff
I seem to spend at least half of my programming life transferring values between an object or structure and some sort of dictionary format.

Swift’s Codable support is really great for doing this when you’ve got JSON or a Plist, but not all dictionary data 
ultimately lives in a file.

For example, I was recently doing some stuff with the Disk Arbitration framework. This has a DADiskCopyDescription call which 
gives you back a dictionary of known keys (many of which may be missing). This dictionary only ever exists in memory.

What I really want to do in this situation is extract some of these keys into a structure or object as a way of validating  that I have what I need, and discarding anything I don’t need.

There will probably be some keys that are essential. If the dictionary doesn’t have them, I want to throw an error.

There may be other keys that are optional. In some cases I’m happy to mark these as optional in the structure, so that I can  tell whether they were in the dictionary. In other cases I want a non-optional property in the structure, and to use a  default value if the dictionary doesn’t have one. Boolean flags are a prime example here - if the flag is in the dictionary,  I want the value, but if not, I want to assume that the flag value is false.

I want to do all this with the absolute minimum of boilerplate, yet I find myself having to write initialisers with this sort  of stuff in them:

```
name = info.stringValue(key: kDADiskDescriptionVolumeNameKey)
device = info.stringValue(key: kDADiskDescriptionMediaBSDNameKey)
id = info.stringValue(key: kDADiskDescriptionMediaUUIDKey)
removeable = info.boolValue(key: kDADiskDescriptionMediaRemovableKey)
```
etc…

The Codable support would be ideal here, except that as it comes out-of-the-box, it appears that I’d have to convert the  dictionary into JSON first in order to convert it back. This seems… non optimal… so I set out to make encoder / decoder  classes which just work with dictionaries.

Here’s One We Made Earlier
After a bit of research I realised that in fact Apple have done almost all the work for me in the implementation of JSONEncoder.swift - they just haven’t exposed it.

It turns out that Foundation’s JSON codable support does in fact work using dictionaries as an intermediate form, but the  code to do so is marked as fileprivate.

Since this is open-source code though, it’s a relatively straightforward task to extract the code, clean up a few things,
and make it into some standalone classes, so that’s what I did.

Usage
The code includes some unit tests which illustrate the basic usage patterns.

In a nutshell, however, it goes like this:

```
struct Pet : Codable {
  let name : String
}

struct Person : Codable {
  let name : String
  let age : Int
  let pets : [Pet]
}

// to encode...
let test = Person(name: "Sam", age: 48, pets:[Pet(name: "Morven"), Pet(name: "Rebus")])
let encoder = DictionaryEncoder()
let encoded = try encoder.encode(test) as [String:Any]
XCTAssertEqual(encoded["name"] as? String, "Sam")
XCTAssertEqual(encoded["age"] as? Int, 48)
let pets = encoded["pets"] as! [NSDictionary]
XCTAssertEqual(pets[0]["name"] as? String, "Morven")
XCTAssertEqual(pets[1]["name"] as? String, "Rebus")

// to decode...
let dict : [String:Any] = [ "name" : "Sam", "age" : 48, "pets" : [ ["name" : "Morven"], ["name" : "Rebus"]]]
let decoder = DictionaryDecoder()
let decoded = try decoder.decode(Person.self, from: dict)

XCTAssertEqual(decoded.name, "Sam")
XCTAssertEqual(decoded.age, 48)
XCTAssertEqual(decoded.pets.count, 2)
XCTAssertEqual(decoded.pets[0].name, "Morven")
XCTAssertEqual(decoded.pets[1].name, "Rebus")
```

Supporting Default Values
Taking Apple’s code gives us the basics of what we need, but one place where it falls down is in its treatment of missing values when decoding.

The way that coding seems to work by default is that if you’re decoding something and a key might be missing, you need to 
mark the corresponding property in your structure as optional. Fail to do this and you’ll throw an error if you try to 
decode something that doesn’t have all the required keys.

That makes sense, but I like to avoid optional values in my structures whenever I can.

It would often be acceptable to substitute a default value for a missing one. The boolean example that I mentioned above 
is a prime example - using false for the value of a missing property will often make perfect sense. Similarly, using "" 
for a missing string property, or 0 for a missing numerical property may often be good enough. You lose the ability to 
tell that the value was actually unspecified, but if it leaves you with a completely optional-free structure, it’s often 
a tradeoff worth making.

It turns out to be relatively simple to add support for this to the code, in the form of a MissingValueDecodingStrategy.

By default, if a value is missing, the old code would throw an error. By setting the missing value strategy to useDefault instead, the code will now attempt to replace missing values with a sensible default. Right now this just works for the 
types mentioned above, and the default value is set

Possible Enhancements
For now, this is just an experiment.

I’m slightly surprised that Apple haven’t exposed this functionality by default - perhaps it was an oversight, or perhaps 
they felt that doing so would encourage a reliance on dictionaries that they’re trying to discourage.

Either way, the code currently feels potentially helpful to me, but time will tell if I actually use it widely or if it’s 
just a curiosity.

If I do use it, there are a few things that could be done to improve it.

Swift Dictionaries
Internally it’s (mostly) working with NS-types, since that’s what the JSON code needed. Native-swift dictionaries are 
bridged, of course, but not without some cost, so one obvious enhancement would be to add a parallel implementation which 
works natively with swift arrays and dictionaries.

More Generic Code
The JSONEncoder source itself contains a surprising amount of repeated boilerplate code. I’m pretty sure it could be 
tidied up and made more compact with some judicious use of generics.

This would probably also simplify the process of producing both NSDictionary and native Swift variants.

Flexible Defaults
One can imagine a few ways to be more sophisticated about supplying default values when keys are missing.

It would be possible to register prototype objects, for example, who’s properties could be copied to fill in missing values.  These could be looked up by type, but also potentially by coding path, perhaps with some wildcard or partial matching. 

JSON-specific Code
Because JSON supports a limited set of types, the original encoding/decoding code has some support in it for dealing with  things like dates - converting them to/from strings so that they can live in a JSON file.

For plain dictionaries, maintaining these restrictions may make a lot of sense, depending on your use case. They aren’t  strictly necessary though - it’s fine to leave some things as native objects in a dictionary.

It might make sense to revisit this code, and either remove it or make it more flexible.
