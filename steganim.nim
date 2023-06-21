import winim
import streams

func toByteSeq*(str: string): seq[byte] {.inline.} =
  @(str.toOpenArrayByte(0, str.high))

proc toString(bytes: openarray[byte]): string =
    result = newString(bytes.len)
    copyMem(result[0].addr, bytes[0].unsafeAddr, bytes.len)

proc nthBitPresent(b: byte,n: int): bool =
    var a = 1 shl n
    var b = int(b) and a
    return b != 0

proc extractByte(a: seq[bool]): byte =

    var b: byte = 0
    for i in 0 .. 7:
        if a[i]:
            b = b or (byte)(1 shl (7 - i))
        else:
            b = b or (byte)(0 shl (7 - i))
    return b

proc extractBytes(a: seq[byte],b: int): seq[byte] =
    
    var c: int = b

    var d: seq[bool] = newSeq[bool](0)
    for i in c .. len(a) - 1:
        d.add(nthBitPresent(a[i], 0))
    var e: seq[byte] = newseq[byte](0)

    for i in countup(0, len(d), 8):
        if len(d) - i > 8:
            var tmp : byte = extractByte(d[i .. i + 8])
            e.add(tmp)
    e = e[1 .. (e.len - 1)]
    var f = toByteSeq("\t")[0]
    var idx = e.find(f);
    var payloadLengthBytes: seq[byte] = e[0 .. idx - 1]
    var p: int
    var msg_len = (cast[ptr int32] (addr payloadLengthBytes[p]))[]
    var finalPayload = e[idx+1 .. (idx + msg_len)]
    return finalPayload

proc getBytesFromFile(path: string): seq[byte] =
    try:
        var
            s = newFileStream(path, fmRead)
            valSeq = newSeq[byte]()
        while not s.atEnd:
            let element = s.readUInt8
            valSeq.add(element)
        s.close()
        return valSeq
    except:
        echo "!! ", path, " was not found !!"
        quit(1)

proc mergeBaseImageWithPayload1BitPerByte(my_byte: byte, ends_in_one: bool): byte =
    var new_byte: byte = my_byte;
    if ends_in_one:
        if not nthBitPresent(my_byte, 0):
            new_byte = cast[byte](my_byte + 1)
    else:
        if (nthBitPresent(my_byte, 0)):
            new_byte = cast[byte](my_byte - 1)
    return new_byte;

proc createSteganoImage(payloadPath: string, baseImagePath: string, outputFile: string): void =
    var 
        payloadBytes: seq[byte] = getBytesFromFile(payloadPath)
        baseImageBytes: seq[byte] = getBytesFromFile(baseImagePath)
        delimiter = toByteSeq("\t")[0]
        start_offset: int = 50
        payloadLengthInBytes = cast[array[sizeof(int32), byte]](payloadBytes.len)
        payloadLengthInBytesReverse: seq[byte] = @[]
    for r in countdown(payloadLengthInBytes.len - 1, 0):
        payloadLengthInBytesReverse.add(payloadLengthInBytes[r])
    payloadBytes = delimiter & payloadBytes

    for b in payloadLengthInBytesReverse:
        payloadBytes = b & payloadBytes

    payloadBytes = delimiter & payloadBytes
    var bits: seq[bool] = newSeq[bool](0)

    for i in countup(0, payloadBytes.len - 1):
        for j in countdown(7,0):
            bits.add(nthBitPresent(payloadBytes[i], j))

    if len(bits) > len(baseImageBytes) + start_offset:
        echo "Payload too big for the image"
        quit(1)

    for i in 0 .. bits.len - 1:
        baseImageBytes[i + start_offset] = mergeBaseImageWithPayload1BitPerByte(baseImageBytes[i + start_offset], bits[i])

    var fHandle = open(outputFile, fmWrite)
    discard writeBytes(fHandle,baseImageBytes,0,baseImageBytes.len)

proc getFromStegano(path: string): seq[byte] =
    var 
        c = getBytesFromFile(path)
        a = 50
        shellcode: seq[byte] = extractBytes(c, a)
    return shellcode

when isMainModule:
    var 
        inputPayload = "input_payload.txt"
        inputBaseImage = "input_base_image.bmp"
        outputSteganoFile = "output_stegano.bmp"
    
    createSteganoImage(inputPayload, inputBaseImage, outputSteganoFile)
    echo toString(getFromStegano(outputSteganoFile))