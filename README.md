# ARC4 Decryption Circuit

[ARC4](https://en.wikipedia.org/wiki/RC4) is a symmetric stream cipher, and was once widely used in encrypting web traffic, wireless data, and so on; it has since been broken. Still, the structure of ARC4 is similar to modern symmetric encryption methods, and provides a good vehicle for studying digital circuits that make extensive use of on-chip memory.

### ARC4 Decryption

A stream cipher like ARC4 uses the provided encryption key to generate a pseudo-random byte stream that is xor'd with the plaintext to obtain the ciphertext. Because xor is symmetric, encryption and decryption are exactly the same.

The basic ARC4 algorithm uses the following parameters:

| Parameter | Type | Semantics |
| --- | --- | --- |
| `key[]` | input | array of bytes that represent the secret key (24 bits in our implementation) |
| `ciphertext[]` | input | array of bytes that represent the encrypted message |
| `plaintext[]` | output | array of bytes that represent the decrypted result (same length as ciphertext) |

and proceeds as shown in this pseudocode:

    -- key-scheduling algorithm: initialize the s array
    for i = 0 to 255:
        s[i] = i
    j = 0
    for i = 0 to 255:
        j = (j + s[i] + key[i mod keylength]) mod 256  -- for us, keylength is 3
        swap values of s[i] and s[j]

    -- pseudo-random generation algorithm: generate byte stream (“pad”) to be xor'd with the ciphertext
    i = 0, j = 0
    for k = 0 to message_length-1:
        i = (i+1) mod 256
        j = (j+s[i]) mod 256
        swap values of s[i] and s[j]
        pad[k] = s[(s[i]+s[j]) mod 256]

    -- ciphertext xor pad --> plaintext
    for k = 0 to message_length-1:
        plaintext[k] = pad[k] xor ciphertext[k]  -- xor each byte

The length of the secret key that we will use is 24 bits (3 bytes) to ensure that you can “crack” the encryption in a reasonable amount of time.

Note that the key is stored [big-endian](https://en.wikipedia.org/wiki/Endianness). The following diagram shows the values of key[0], key[1], and key[2] for the 24-bit secret key of 'b000000110101111100111100 = 'h035F3C.

<p align="center"><img src="figures/key-endianness.svg" title="key endianness" width="60%" height="60%"></p>


### The ready-enable microprotocol

The handshake has two sides: the “caller” and the “callee.” Whenever the callee is ready to accept a request, it asserts its `rdy` signal. If `rdy` is asserted, the caller may assert `en` to make a “request” to the callee. The following timing diagram illustrates this:

<p align="center"><img src="figures/rdy-en.svg" title="ready-enable microprotocol" width="65%" height="65%"></p>

It is illegal for the caller to assert `en` if `rdy` is deasserted; if this happens, the behaviour of the callee is undefined.

Whenever `rdy` is asserted, it means that the callee is able to accept a request _in the same cycle_. This implies that a module that needs multiple cycles to process a request and cannot buffer more incoming requests **must** ensure `rdy` is deasserted in the cycle following the `en` call. Similarly, each cycle during which the `en` signal is asserted indicates a distinct request, so the caller must ensure `en` is deasserted in the following cycle if it only wishes to make a single request. The following timing diagram shows an example of this behaviour:

<p align="center"><img src="figures/rdy-en-singleclock.svg" title="ready-enable microprotocol" width="65%" height="65%"></p>

This microprotocol allows the callee to accept multiple requests and buffer them.

Finally, some requests come with arguments. For example, Task 3 requires you to write a decrypt module which follows the ready/enable microprotocol and takes the secret key as an argument. In this case, the argument port must be valid **at the same time** as the corresponding `en` signal, as in this diagram:

<p align="center"><img src="figures/rdy-en-arg.svg" title="ready-enable microprotocol with an argument" width="65%" height="65%"></p>


### ARC4 state initialization

The `src` folder you will find a `init5.sv` will implement the first step of ARC4, where the cipher state S is initialized to [0..255]:

    for i = 0 to 255:
        s[i] = i

The `init` module follows the ready/enable microprotocol.

### The Key-Scheduling Algorithm

Many symmetric ciphers, including ARC4, have a phase called the _Key-Scheduling Algorithm_ (KSA). The objective of the KSA is to spread the key entropy evenly across _S_ to prevent statistical correlations in the generated ciphertext that could be used to break the cipher. ARC4 does this by swapping values of _S_ at various indices:

    j = 0
    for i = 0 to 255:
        j = (j + s[i] + key[i mod keylength]) mod 256   -- for us, keylength is 3
        swap values of s[i] and s[j]

In folder `src` you will find `ksa4.sv`, which you will fill out to implement the KSA phase. Like `init`, the `ksa` module will implement the ready/enable microprotocol.

### The Pseudo-Random Generation Algorithm

The final phase of ARC4 generates the bytestream that is then xor'd with the input plaintext to encrypt the message, or, as in our case, with the input ciphertext to decrypt it. We don't need the bytestream by itself, so in this task we will combine both.

    i = 0, j = 0
    for k = 0 to message_length-1:
        i = (i+1) mod 256
        j = (j+s[i]) mod 256
        swap values of s[i] and s[j]
        pad[k] = s[(s[i]+s[j]) mod 256]

    for k = 0 to message_length-1:
        plaintext[k] = pad[k] xor ciphertext[k]  -- xor each byte

First, generate two additional memories: one to hold the ciphertext (instance name _CT_), and another where you will write the plaintext (instance name _PT_). Both will be 8-bit wide and 256 8-bit words deep, and will connect to your ARC4 decryption module:

<p align="center"><img src="figures/arc4-module.svg" title="decryption module" width="50%" height="50%"></p>

Both the plaintext and ciphertext are stored starting at address 0 as length-prefixed strings (described earlier).

Then, implement the bytestream/xor functionality in the `prga.sv` file in the `task3` folder. This has interfaces for all three memories. As before, the module obeys the rdy/en protocol. Note that the `prga` module **must not** include the functionality of `init` or `ksa`. Comprehensively test this in `tb_rtl_prga.sv` and `tb_syn_prga.sv`.

Next, complete the ARC4 algorithm by filling out `arc4.sv`. This should instantiate the _S_ memory and the three submodules, and activate everything in the right order to decrypt the ciphertext in the _CT_ memory (a length-prefixed string starting at address 0) and write the plaintext to _PT_ (which should also be a length-prefixed string at address 0). The `arc4` module also obeys rdy/en, and makes no assumptions about the key. The comprehensive testbenches go in `tb_rtl_arc4.sv` and `tb_syn_arc4.sv`.

Finally, implement the toplevel `task3` module in `task3.sv`. The template file instantiates the _CT_ and _PT_ memories; you will need to add `arc4` and connect everything together. As in Task 2, hardwire the top 14 bits of the key to 0 _in the toplevel only_ and use the switches for the rest; assign reset to `KEY[3]`. The testbenches for this will be in `tb_rtl_task3.sv` and `tb_syn_task3.sv`.

You can check that your circuit is working on the FPGA by using key `'h1E4600` to decrypt the following ciphertext:

    A7 FD 08 01 84 45 68 85 82 5C 85 97 43 4D E7 07 25 0F 9A EC C2 6A 4E A7 49 E0 EB 71 BC AC C7 D7 57 E9 E2 B1 1B 09 52 33 92 C1 B7 E8 4C A1 D8 57 2F FA B8 72 B9 3A FC 01 C3 E5 18 32 DF BB 06 32 2E 4A 01 63 10 10 16 B5 D8

(this is just the ciphertext itself, without the length prefix). You will also find this in $readmemh() format and MIF format as `test1.{memh,mif}` (these files include the length prefix). The result should be a sentence in English.


### Cracking ARC4

Now comes the shaken-not-stirred part: you will decrypt some encrypted messages _without_ knowing the key ahead of time.

How will we know if we've decrypted the messages correctly, though? The insight here is that messages that we are looking for are human-readable. For the purposes of this lab, an encrypted message is deemed to be cracked if its characters consist entirely of byte values between 'h20 and 'h7E inclusive (i.e., readable ASCII).

The `crack` module is very much like `arc4`, but both _S_ and _PT_ are now internal, _key_ is now an output, and the new _key_valid_ output indicates that _key_ may be read. On `en`, this module should sequentially search through the key space starting from key 'h000000 and incrementing by 1 every iteration (to make marking tractable). Once the computation is complete, it should assert `rdy` and, only if it found a valid decryption key, also set `key_valid` to 1 and `key` to the discovered secret key. If `key_valid` is 1, the `pt` memory inside `crack` should contain the corresponding plaintext in length-prefixed format.

To help you debug, here are two encrypted sentences for which the keys are very small numbers (≤ 10):

    4D 21 74 1A E2 D6 91 12 F3 BA 6B 95 D1 E3 68 5A 9E 7A 60 A7 87 01 54 64 20 DD 84 9A A2 A9 B8 A0 4B 86 30 1D A6 65 E0 4A F7 A6 54 D6 43

    83 7B 02 41 0F 0E C8 35 A4 EB 87 00 0F A7 DB 4E 28 1A 0C 30 CD 95 32 DF 3B 96 58 7D 70 29 2A 0B 69 BF E9 53 61 F0 73 6C E1 C2 94 D2 31 8E 34 40 6F AF 52 53 2D 95 20 28 60 D1 DB A6 1C 87 E1 83 BD 81 A6 25 FB A2 93 A8 E6 F4 AD 20

(Don't forget about the length when loading them into the _CT_ memory!) Naturally, the unit tests go in `tb_rtl_crack.sv` and `tb_syn_crack.sv`.

The toplevel `task4` module should, on reset, use `crack` to process the message in the _CT_ memory and display the _key_ on the seven-segment displays on the DE1-SoC: if the key is 'h123456 then the displays should read “123456” left-to-right when the board is turned so that the switch bank and the button keys are towards you. The displays should be _blank_ while the circuit is computing (i.e., you should only set them after you have found a key), and should display “------” if you searched through the entire key space but no possible 24-bit key resulted in a cracked message (as defined above). The hex digits should look like this:

<p align="center"><img src="figures/hex-digits.svg" title="hex digits" width="60%" height="60%"></p>

The tests for `task4` go in `tb_rtl_task4.sv` and `tb_syn_task4.sv`, as usual.

Remember to check that the instance hierarchy for the memories is correct. Starting from `task4`, the memories should be accessible as

    ct.altsyncram_component.m_default.altsyncram_inst.mem_data
    c.pt.altsyncram_component.m_default.altsyncram_inst.mem_data
    c.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data

in RTL simulation, and

    \ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem
    \c|pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem
    \c|a4|s|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem

in netlist simulation.


### Cracking in parallel

To speed up cracking, we will now run two `crack` modules at the same time: the first will start the search at 0 and increment by 2, and the second will start at 1 and also increment by 2. You will implement this in `doublecrack`. The `doublecrack` module instantiates two `crack` modules. For this task (and only in this folder), you may **add** ports to the `crack` module in this task, but you **may not** remove or modify existing ports.

The `doublecrack` ports are the same as in the `crack` module in Task 4; in particular, it has access to only one port of _CT_ (the other port is taken by the In-System Memory Editor anyway). You will have to decide how to handle this inside `doublecrack`; there are several elegant solutions and some hacky ones. We will expect your `doublecrack` to be faster than the fastest possible implementation of `crack`, and about twice as fast as your `crack`.

The `doublecrack` also instantiates one shared _PT_ memory. The final length-prefixed plaintext must be in this memory if `key_valid` is high regardless of which `crack` core decrypted the message. Each `crack` core will have its own _PT_ memory as well; the length-prefixed plaintext must also be in the _PT_ memory in the `crack` core that decrypted it.

Feel free to create additional instances of the memories you've already generated (`s_mem`, `ct_mem`, and `pt_mem`), provided you do not change the instance IDs or configurations of the memories predefined in the skeleton files.

The toplevel `task5` should do exactly the same thing as `task4` but about twice as quickly. As before, you will need comprehensive testbenches in `tb_rtl_doublecrack`, `tb_rtl_crack`, `tb_rtl_task5`, `tb_syn_doublecrack`, `tb_syn_crack`, and `tb_syn_task5`. Because you will likely modify the `crack` module, its testbench in this task must be comprehensive even if you already tested most of it in Task 4.

_Hint:_ Do not be discouraged by highfalutin' words like “parallel” — if you have a working `crack` module, this task is actually quite easy.

Remember to check that the instance hierarchy for the memories is correct so the autograder can access them. Starting from `task5`, the memories we care about should be accessible as

    ct.altsyncram_component.m_default.altsyncram_inst.mem_data
    dc.pt.altsyncram_component.m_default.altsyncram_inst.mem_data
    dc.c1.pt.altsyncram_component.m_default.altsyncram_inst.mem_data
    dc.c2.pt.altsyncram_component.m_default.altsyncram_inst.mem_data

in RTL simulation, and

    \ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem
    \dc|pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem
    \dc|c1|pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem
    \dc|c2|pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem

in netlist simulation.

