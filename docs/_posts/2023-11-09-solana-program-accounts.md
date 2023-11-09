---
layout: post
title:  "Solana Program Accounts"
description: "Wait a minute.... this seems like C++..."
author: "h0bb3"
comments_id: 21
tags: "programming coding dev Solana blockchain account"
---

Solana uses the concept of an account to store data on the blockchain. You can basically think of it as a file (adapted to live on the blockchain and not on your hard drive) if you prefer that. In this post, I will explore Solana programs from an accounts perspective. Programs can live on the blockchain (i.e. smart contracts) and programs themselves are data (the program code). Programs are also stored as accounts. When doing something on a blockchain, e.g. creating an account, this has an incurred cost. The cost is used to make the economics of the chain viable (you can compare it to hosting on a server, it will cost you some money). When I deployed my small program the cost was approximately 2.7 SOL. In Solana this is called rent - but actually, it is a one-time fee based (if you deposit enough SOL you become rent exempt and this is actually the only way at this point) on the size of the account allocated.

As an example, I created a small Solana program with the simple task of being able to increment a counter. This program got the address: `EZjcYhYGdJTNBbZ4wi59ZgBpyDLNAMgMQB3iUBvpsQ3f` and after deployment, this is the address to the program account. I got curious about my newly created program account and decided to look it up on the Solana chain.

```
solana account EZjcYhYGdJTNBbZ4wi59ZgBpyDLNAMgMQB3iUBvpsQ3f

Public Key: EZjcYhYGdJTNBbZ4wi59ZgBpyDLNAMgMQB3iUBvpsQ3f
Balance: 0.00114144 SOL
Owner: BPFLoaderUpgradeab1e11111111111111111111111
Executable: true
Rent Epoch: 18446744073709551615
Length: 36 (0x24) bytes
0000:   02 00 00 00  59 25 9d 3b  db fd b2 16  89 3e 88 bf   ....Y%.;.....>..
0010:   a0 e4 42 7b  fd 26 ac e6  8a b2 bd 4e  61 5f 72 50   ..B{.&.....Na_rP
0020:   8a 01 fb f4                                          ....
```

What intrigued me here was that the balance of the account was not at all near 2.7 SOL and the size of the account was really small. Something did not add up and after digging a bit further it turns out that each program is split into two accounts: one for program info, and one for the actual program code. The first has the address that you use to find the program, the second is referenced by the data of the first. More specifically the last 31 bytes are encoded in `base58` format. 

There are 36 bytes of data and the last 31 bytes are: `259d3bdbfdb216893e88bfa0e4427bfd26ace68ab2bd4e615f72508a01fbf4` decoded from base58 gives address `6zzYyXMM7Xgbvkgn4DSw1xMhZ3YQ6AK9XCVvkYFiBTvj` and it is at this address we find the actual program code.

```
solana account 6zzYyXMM7Xgbvkgn4DSw1xMhZ3YQ6AK9XCVvkYFiBTvj | head -10

Public Key: 6zzYyXMM7Xgbvkgn4DSw1xMhZ3YQ6AK9XCVvkYFiBTvj
Balance: 2.7269628 SOL
Owner: BPFLoaderUpgradeab1e11111111111111111111111
Executable: false
Rent Epoch: 18446744073709551615
Length: 391677 (0x5f9fd) bytes
0000:   03 00 00 00  33 6a 03 00  00 00 00 00  01 df 7d 6a   ....3j........}j
0010:   de 08 d4 4a  b4 45 84 f0  fb 8f 0b 00  a7 48 56 4a   ...J.E.......HVJ
0020:   5a 4b e0 fd  b7 dc af 32  1a 59 79 f9  b2 7f 45 4c   ZK.....2.Yy...EL
...
```

This is were the main cost of the rent went and it seems it allocates x2 of the size of the actual built program code file. This is likely to give room for some updates. I would asume this is a downside of developing solana programs - a relatively high cost of deployment as programs tend to be rather large. In normal web development the actual deployment is cheap (but usage at scale is expensive). Would be interesting to make a calculation and see if a blockchain can compete here - but that is for some other time...

Another interesting aspect about programs is that you then create instances of the programs that store the actual data the program manipulates. In my simple case incrementing the counter. The instances of the programs are ofcourse accounts that store the state of the specific program-instance:

```
 solana account 9TNpACRaaeem3X2FehZXgsRpsBTnvZG7xVm8ra4LMdFG

Public Key: 9TNpACRaaeem3X2FehZXgsRpsBTnvZG7xVm8ra4LMdFG
Balance: 0.0011136 SOL
Owner: EZjcYhYGdJTNBbZ4wi59ZgBpyDLNAMgMQB3iUBvpsQ3f
Executable: false
Rent Epoch: 18446744073709551615
Length: 32 (0x20) bytes
0000:   10 5a 82 f2  9f 0a e8 85  0a 00 00 00  00 00 00 00   .Z..............
0010:   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   ................
```

The `0a` byte is the byte that holds the value 10 for my fun solana counter. We can note the owner account that is the same as the program info account.

In the client code the program-info account and the instance-account are tided together so the code referenced by the program can be executed on the instance. One may say that this is a bit similar to how C++ works behind the scenes, the code of a class is actually one part of the memory that is referened and shared by each object (the data) to execute the code over the objects memory - the program code is thus reused for every object.

Indeed interesting and looking through this sure made me get a better and deeper understanding of the architecture of Solanas program accounts.
