---
layout: post
title:  "Python and Solana"
description: "not a love story"
author: "h0bb3"
comments_id: 17
tags: "programming coding dev Solana blockchain account python"
---
Well a lot has happened since my last post. Basically going full time with our blockchain-based DePin Energy project [srcful](https://srcful.io). This is all mighty exciting from different points of view but I will not talk further about that atm.

Today we are talking about python and [solana](https://solana.com). Solana the blockchain where our token will live and as such one of the building blocks of our company and community. Solana has a strong connection to the Rust programming language (as it is the smart contract language of Solana) and javascript as it is the language of the web(3). So why Python then? Well, it is the language that our gateway firmware is written in mostly as it has great libs for interacting with eg. hardware things (such as inverters and crypto chips), it is good as a nice and clear "backend" language in that sense. There is then an odd chance that our gateway would need to interract the solana blockchain in one way or the other.

Traditionally python has a strong suite of libraries maybe with a focus on numerical computation, machine learning and AI. I was more or less sure that there would be a strong suite of libs also for interaction with the solana blockchain. As it turns out - not so much. So I will give you my current experiences and how I could work around them.

For starters there are some good basic libraries that seem to be well maintained and you should definitely use these. They kind of build on eachother also so... The first is [solders](https://github.com/kevinheavey/solders) which gives you excellent solana primitives to work with. The second is [Solana.py](https://github.com/michaelhly/solana-py) that handles the connectivity and communication stuff. I would say these seem excellent and active, use them.

The problem is what comes next after the basics. In essence what is interesting with blockchains are the programs that they can run, what is called smart contracts. You can think of a (modern) blockchain as a great state machine, where every state transition is recorded and controlled by programs that run on the chain itself. These programs react to (external) events, someone calls a function of the program from the outside. The program validates this call and if everything checks out it will alter the state accordingly (this includes checking that things have been signed by the correct parties etc). E.g. if you want to transfer something from one account to another you use the corresponding program to do so (e.g. the [solana system program transfer](https://docs.rs/solana-program/latest/solana_program/system_instruction/fn.transfer.html).

Naturally program creation on solana is not a centrally managed thing. Anyone can create a program - and will need to provide the respective bindings for client code to interact with the program in a nice way. As said this seems to work out well for Rust, and js (as mentioned before). Not so much for python. E.g. the extension of tokens to token22 is not included in the above mentioned libs (and I could not find any other either, that seemed trustworthy). Another popular token metadata standard is the [metaplex](https://www.metaplex.com/) standard. And while they have an api implementation in python it has not been updated in 3 years (https://github.com/metaplex-foundation/python-api) :(

Another quite interesting project to genereate such bindings is [anchorpy](https://github.com/kevinheavey/anchorpy). I think this has great potential but it did not work when I tried to generate the metaplex bindings for the token metadata program, (also described in an issue)[https://github.com/kevinheavey/anchorpy/issues/114].

This basically leaves you a bit down to manually understanding how program invocation, function argument serialization is done on solana. Fortunately it is quite fun to dwelve into the bits and bytes.

So without further adue lets take a look at some code snippets.

First, if you have a token22 program and not a token program you cannot just take the data from the loaded account and create a `TokenAccount` instance from it. This will fail as the data for a token22 program is compatible, but has more things in it, so (the first 165 bytes are what is compatible)[https://spl.solana.com/token-2022#mints-and-accounts], so you need to limit things to this:
```python
ta = TokenAccount.from_bytes(account.value.data[:165])
```

If you have a token22 program the associated token account adresses are generated differently and you would need to roll your own using as the built in method is hard coded for the normal token program adress. I made a helper for this where you send in the token program you use.

```python
def get_associated_token_address(account: Pubkey, token: Pubkey, owner:Pubkey) -> Pubkey:
    return Pubkey.find_program_address([bytes(account), bytes(owner), bytes(token)], ASSOCIATED_TOKEN_PROGRAM_ID)
```

To manage the token22 built in metadata extensions you need to load the token account and iterate what is beyond the normal token account size. Then check for the correct extension number (19) and parse the bytes according to the [corresponding rust code](https://github.com/solana-labs/solana-program-library/blob/c4d51f20b8722d23b03e94c7075702fca52460dd/token-metadata/interface/src/state.rs#L25).

```python
def parse_tlv_header(byte_array):
    if len(byte_array) < 4:
        raise ValueError("Byte array is too short to contain a valid TLV header")

    # Unpack the type (2 bytes) and length (2 bytes) as unsigned short (big-endian)
    type_field, length_field = struct.unpack_from('<HH', byte_array, 0)
    
    return type_field, length_field

def read_next_string(byte_array, start):
    # Read the length of the string (4 bytes) as unsigned int (little-endian)
    length = struct.unpack_from('<I', byte_array, start)[0]
    start += 4

    # Read the string itself
    string = byte_array[start:start + length].decode('utf-8')
    start += length

    return string, start

async def get_token_name_symbol(client: AsyncClient, token: Pubkey):

    # the account may have meta data as an extension
    mint_account = await client.get_account_info(token, commitment.Finalized)
    assert mint_account.value.owner in {TOKEN_PROGRAM_ID, TOKEN_2022_PROGRAM_ID}

    headerIx = 166
    while headerIx < len(mint_account.value.data):
        type, length = parse_tlv_header(mint_account.value.data[headerIx:])
        if type == 19:

            # basic strings start here each prepended with an u32 length
            string_start = headerIx + 4 + 64
            name, string_start = read_next_string(mint_account.value.data, string_start)
            symbol, string_start = read_next_string(mint_account.value.data, string_start)
            uri, string_start = read_next_string(mint_account.value.data, string_start)

            return name, symbol
            
        headerIx += length + 4

    return "unknown token", 'n/a'
```

One fun thing is that the number 19 corresponds to [the enum index in the rust code](https://github.com/solana-labs/solana-program-library/blob/63b3a25c9e61204973f5520a76a337d457fd8e4e/token/program-2022/src/extension/mod.rs#L1093).

This is all quite low level and fun if you are into things like that. Another approach would be to use the borsh serialization library that is actually used by solana programs. This way you can define a structure and then read/write to this structure. You will still need to check the corresponding Rust program for the structure. E.g. for the metaplex token metadata you can use the following structure.

```python
instruction_structure = CStruct(
    "instructionDiscriminator" / U8,
    "createMetadataAccountArgsV3" / CStruct( # https://github.com/metaplex-foundation/mpl-token-metadata/blob/5c7672c7b7cd671c7afbdaeed52819e9a7a3259f/programs/token-metadata/program/src/instruction/metadata.rs#L32
        "data" / CStruct(                       # https://github.com/metaplex-foundation/mpl-token-metadata/blob/5c7672c7b7cd671c7afbdaeed52819e9a7a3259f/programs/token-metadata/program/src/state/data.rs#L22
            "name" / String,
            "symbol" / String,
            "uri" / String,
            "sellerFeeBasisPoints" / U16,
            "creators" / Option(Vec(CStruct(
                "address" / Bytes(32),
                "verified" / Bool,
                "share" / U8
            ))),
            "collection" / Option(CStruct(
                "verified" / Bool,
                "key" / String
            )),
            "uses" / Option(CStruct(
                "useMethod" / Enum(
                    "Burn",
                    "Multiple",
                    "Single",
                    enum_name="UseMethod"
                ),
                "remaining" / U64,
                "total" / U64
            ))
        ),
        "isMutable" / Bool,
        "collectionDetails" / Option(String) # fixme: string is not correct, insert correct type
    )
)
```
Again the `instructionDiscriminator` will be set to a number that corresponds to an enum index i the Rust program that defines the instructions. In this case it will be set to 33 that corresponds to [createMetadataAccountV3 ](https://github.com/metaplex-foundation/mpl-token-metadata/blob/5c7672c7b7cd671c7afbdaeed52819e9a7a3259f/programs/token-metadata/program/src/instruction/mod.rs#L49)

This was a bit of a brain-dump of my latest adventures in the realm of Solana and Python. It seems that there are a number of interesting beast to slay in this here.
