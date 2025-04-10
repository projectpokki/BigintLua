local Bigint = require(workspace.BigintLibrary)
local testCase = 0


function test(bigintOutput, expectedOutput)
	testCase += 1

	if tostring(bigintOutput) ~= expectedOutput then
		error("test case " .. testCase .. " get " .. tostring(bigintOutput) .. " intead of " .. expectedOutput, 2)
	end
	task.wait()
end

test(Bigint.strip({0, 0, 10000, 0, 20000, 30000, 0, 0, 0, 0}), "0x007530 004e20 000000 002710 000000 000000")

test(Bigint.tohex(Bigint.new("54673288756493265451627341823597")), "0x0002b212ec7bdfdd75f20494d63e6d")
test(Bigint.tohex(Bigint.new("13")), "0x00000d")
test(Bigint.tohex(Bigint.new("0")), "0x0")

test(Bigint.tohexf(Bigint.new("54673288756493265451627341823597")), "0x0002b2 12ec7b dfdd75 f20494 d63e6d")
test(Bigint.tohexf(Bigint.new("13")), "0x00000d")
test(Bigint.tohexf(Bigint.new("0")), "0x0")

test(Bigint.tonumber(Bigint.new("4832947893264782915436728154823672814")), "4.832947893264783e+36")
test(Bigint.tonumber(Bigint.new("100000000000000000000000000000000000000000000")), "1e+44")
test(Bigint.tonumber(Bigint.new("432432553200")), "432432553200")
test(Bigint.tonumber(Bigint.new("0")), "0")

test(Bigint.tointstr(Bigint.new("432432553200")), "432432553200")
test(Bigint.tointstr(Bigint.new("55325325253253253254754273454")), "55325325253253253254754273454")
test(Bigint.tointstr(Bigint.new("0")), "0")

test(Bigint.new("5453543") == Bigint.new("5453543"), "true")
test(Bigint.new("59714738247836275846325743785639463289") == Bigint.new("59714738247836275846325743785639463289"), "true")
test(Bigint.new("59714738247836275846325743329463289") == Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("48239478932784932") == Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("5789169032478382647832647832") == Bigint.new("327846237923523"), "false")

test(Bigint.new("5453543") > Bigint.new("5453543"), "false")
test(Bigint.new("59714738247836275846325743785639463289") > Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("59714738247836275846325743329463289") > Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("48239478932784932") > Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("5789169032478382647832647832") > Bigint.new("327846237923523"), "true")

test(Bigint.new("5453543") >= Bigint.new("5453543"), "true")
test(Bigint.new("59714738247836275846325743785639463289") >= Bigint.new("59714738247836275846325743785639463289"), "true")
test(Bigint.new("59714738247836275846325743329463289") >= Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("48239478932784932") >= Bigint.new("59714738247836275846325743785639463289"), "false")
test(Bigint.new("5789169032478382647832647832") >= Bigint.new("327846237923523"), "true")

test(Bigint.max(Bigint.new("6483294789327483248723"), Bigint.new("3294678326473267482")), "0x000001 5f75ca 14ece5 a32053")
test(Bigint.max(Bigint.new("7232235"), Bigint.new("3294678326473267482")), "0x002db9 0c7b62 9e191a")

test(Bigint.min(Bigint.new("6483294789327483248723"), Bigint.new("3294678326473267482")), "0x002db9 0c7b62 9e191a")
test(Bigint.min(Bigint.new("7232235"), Bigint.new("3294678326473267482")), "0x6e5aeb")

test(Bigint.bitand(Bigint.new("923048903284903289403"), Bigint.new("10278346372647832")), "0x000020 040200 0a8218")

test(Bigint.bitor(Bigint.new("923048903284903289403"), Bigint.new("10278346372647832")), "0x3209e4 f71bd2 efabbb")

test(Bigint.bitxor(Bigint.new("923048903284903289403"), Bigint.new("10278346372647832")), "0x3209c4 f319d2 e529a3")

test(Bigint.lshiftdoubles(Bigint.new("837287832"), 8), "0x000031 e7ff98 000000 000000 000000 000000 000000 000000 000000 000000")

test(Bigint.rshiftdoubles(Bigint.new("83724234324324326387832"), 2), "0x000011 bab328")

test(Bigint.lshiftbits(Bigint.new("83724234324324326387832"), 13), "0x023756 6510fe facca6 0f0000")

test(Bigint.rshiftbits(Bigint.new("83724234324324326387832"), 13), "0x008dd5 99443f beb329")

test(Bigint.lendoubles(Bigint.new("329864783256436757483562748328923164782")), "0x000006")

test(Bigint.lenbits(Bigint.new("329864783256436757483562748328923164782")), "0x000080")

test(Bigint.new("0xffffffffffffffffffffffff") + Bigint.new("0xffffffffffff"), "0x000001 000000 000000 ffffff fffffe")
test(Bigint.new("4783748324") + Bigint.new("43234324318100"), "0x275363 ad3c78")
test(Bigint.new("0xffffffffffffffffffffffff") + Bigint.new("0xffffffffffff"), "0x000001 000000 000000 ffffff fffffe")
test(Bigint.new("43243274673264732648246732") + Bigint.new("0127401457615325"), "0x0023c5 1e9e08 499989 d40fa9")

test(Bigint.subabs(Bigint.new("837482394283294723"), Bigint.new("21746738264782")), "0x000b9f 42059a 4a4535")
test(Bigint.subabs(Bigint.new("32525837482394283294723"), Bigint.new("22425535321746738264782")), "0x000002 2389d9 a56a23 560535")
test(Bigint.subabs(Bigint.new("143829748392784235"), Bigint.new("22425535321746738264782")), "0x000004 bfaed3 1b27fc 8e4963")
test(Bigint.subabs(Bigint.new("13"), Bigint.new("13")), "0x0")

test(Bigint.new("837482394283294723") - Bigint.new("21746738264782"), "0x000b9f 42059a 4a4535")
test(Bigint.new("32525837482394283294723") - Bigint.new("22425535321746738264782"), "0x000002 2389d9 a56a23 560535")
test(Bigint.new("143829748392784235") - Bigint.new("22425535321746738264782"), "0x0")
test(Bigint.new("13") - Bigint.new("13"), "0x0")

test(Bigint.new("432473290749023") * Bigint.new("18034783927589324932043"), "0x000005 de241d 175cd6 8e45aa dde83b 8ee455")

test(Bigint.new("432473290749432432023") // Bigint.new("1803343398043"), "0x00000e 4b5313")

test(Bigint.new("432473290749432432023") / Bigint.new("1803343398043"), "239817491.89796865")

test(Bigint.new("432473290749432432023") % Bigint.new("53253257788"), "0x0009e9 4f8dfb")

test(Bigint.square(Bigint.new("48397284325473284932932094595")), "0x5f86b9 1c1dd0 740a27 bdfb3c c0341a ca5c6d 5f4020 2bff09")

test(Bigint.gcd(Bigint.new("59325068029210"), Bigint.new("28897814750589764")), "0x00591d 3927ee")

test(Bigint.lcm(Bigint.new("59325068029210"), Bigint.new("28897814750589764")), "0x003e29 2d7554 0fca2c")

test(Bigint.new("1987747") ^ Bigint.new("19"), "0x002e3f c11d23 ddc3e9 2e8a6e ecf382 89456e 37380f 0193b6 88a4f5 d00377 59066a 91d36c 6ed77f b22508 d0262d 7c4e7a 69f6bb")

test(Bigint.powmod(Bigint.new("9292074612787382"), Bigint.new("12399"), Bigint.new("10000011111")), "0x0001aa 2e6793")
test(Bigint.powmod(Bigint.new("9292074612787382"), Bigint.new("0"), Bigint.new("10000011111")), "0x000001")

test(Bigint.sqrt(Bigint.new("29874325647327849236478632978")), "0x9d32e4 9ccba0")

test(Bigint.root(Bigint.new("90816437251237878923748325463256737824738"), Bigint.new("9")), "0x008ae3")

test(Bigint.log2(Bigint.new("48327493209892765632715637")), "0x000055")

test(Bigint.log(Bigint.new("48327493209892765632715637"), Bigint.new("3")), "0x000035")

test(Bigint.fact(Bigint.new("24")), "0x000083 629343 d3dcd1 c00000")
test(Bigint.fact(Bigint.new("60")), "0x000118 b5727f 009f52 5dcfe0 d58e86 53c742 de9d88 9c2efe 3c5516 f88700 000000 000000")

test(Bigint.nPr(Bigint.new("183"), Bigint.new("90")), "0x003abe 97f9d8 bcb631 b89d23 a6bd23 97a10d 69d9a6 50e93a 492ce9 c9c7b2 5c9911 edc7ee 5f8405 b1bac2 86befd 3ec5b7 ecfe35 881d9b e06b1a bfe041 72cc9a f30dbd 60779a 360000 000000 000000 000000")

test(Bigint.nCr(Bigint.new("283"), Bigint.new("190")), "0x004a42 a89014 96c8ff ac2f28 b83054 e6782d 2554d7 0cbaa8 d7ac20 74176a 08af40")

print(testCase .. " tests complete, no errors")
