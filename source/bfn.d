module bfn;
//Information from this file comes from RenolY2's work and the contributors of https://wiki.cloudmodding.com/tww/BFN
import arsd.png;
import binary.reader;
import binary.writer;
import binary.common;
//import imageformats;
import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.file;
import std.format;
import std.math;
import std.path;
import std.range;
import std.stdio;
import std.string;
import vibe.data.json; //Used to write and read from the JSON helper file
import vibe.data.serialization;

///A struct detailing the elements found in an INF1 Section
struct INF1Section {
    string section_name;
    uint section_size;
    ushort encoding;
    ushort ascent;
    ushort descent;
    ushort width;
    ushort leading;
    ///Replacement code (not character). The game will substitute unmapped characters with this code. It is assumed this code will have a valid glyph assigned to it.
    ushort fallback_code;
    uint unk1;
    //0x8 Padding
}

///A struct detailing the elements found in an GLY1 Section
struct GLY1Section {
    string section_name;
    uint section_size;
    ushort start_glyph;
    ushort end_glyph;
    ushort cell_width;
    ushort cell_height;
    uint page_data_size;
    ushort texture_format;
    ushort glyph_horizontal_count;
    ushort glyph_vertical_count;
    ushort texture_width;
    ushort texture_height;
    //0x2 Padding
    //(end_glyph - start_glyph) / (glyph_horizontal_count * glyph_vertical_count) Image files
}

///A struct detailing the elements found in a MAP1 Section
struct MAP1Section {
    string section_name;
    uint section_size;
    ///0 = Linear Mapping, 1: Linear S-JIS Kanji, 2: table mapping, 3: map mapping. More info at https://wiki.cloudmodding.com/tww/BFN
    ushort mapping_type;
    ushort first_char;
    ushort last_char;
    ushort mapping_entry_count;
    @embedNullable ushort[] entries; //Some MAP1 sections dont have any entries
}

///A struct detailing the elements found in a WID1 Section
struct WID1Section {
    string section_name;
    uint section_size;
    ushort first_code_included;
    ushort last_code_included;
    WID1Packet[] packets; ///Length is last_code_included - first_code_included
}

///A struct detailing the elements found in a W1D1 Packet
struct WID1Packet {
    ubyte kerning;
    ubyte width;
}

///A struct used to contain all BFN info before outputting to a json file
struct BFNInfo {
    INF1Section[] inf1;
    GLY1Section[] gly1;
    MAP1Section[] map1;
    WID1Section[] wid1;
}

///Returns a ubyte from the target file
ubyte readU8(File bfn) {
    ubyte[] data;
    data.length = 1;
    bfn.rawRead(data);
    auto reader = binaryReader(data);
    return reader.read!ubyte;
}

///Returns a ushort from the target file
ushort readU16(File bfn) {
    ubyte[] data;
    data.length = 2;
    bfn.rawRead(data);
    auto reader = binaryReader(data, ByteOrder.BigEndian);
    return reader.read!ushort;
}

///Returns a uint from the target file
uint readU32(File bfn) {
    ubyte[] data;
    data.length = 4;
    bfn.rawRead(data);
    auto reader = binaryReader(data, ByteOrder.BigEndian);
    return reader.read!uint;
}

///Reads a certain amount of characters, combining them into a returned string
string readString(File bfn, uint charAmount) {
    ubyte[] data;
    data.length = charAmount;
    bfn.rawRead(data);
    return cast(string)data;
}

///Reads a certain amount of bytes without parsing them
void skipAmount(File bfn, uint amount) {
    ubyte[] data;
    data.length = amount;
    bfn.rawRead(data);
    return;
}

///Reads a certain amount of bytes, returning them as a ubyte array 
ubyte[] readAmount(File bfn, uint amount) {
    ubyte[] data;
    data.length = amount;
    return bfn.rawRead(data);
}

///Creates an image from glyph image data, outputting a png file
void extractImage(File bfn, string folderName, uint page_data_size, ushort texture_format, ushort texture_width, ushort texture_height, string fileName = "char.png") {
    TrueColorImage outputImage = new TrueColorImage(texture_width, texture_height);
    auto colorData = outputImage.imageData.colors;
    ubyte[] glyphData = readAmount(bfn, page_data_size);
    uint i = 0;
    assert(texture_format == 2 || texture_format == 0); //Texture Format is either IA4 or I4
    writefln("Image Format of %s: %s", fileName, texture_format);
    writefln("Image Width: %s Image Height: %s", texture_width, texture_height);
    if (texture_format == 2) {
        for (ubyte iy = 0; iy < (texture_height/4); iy++) {
            for(ubyte ix = 0; ix < (texture_width/8); ix++) {
                for (ubyte y = 0; y < 4; y++) {
                    for (ubyte x = 0; x < 8; x++) {
                        ubyte intensity = (glyphData[i] & 0xF) * 16;
                        ubyte alpha = ((glyphData[i] >> 4) & 0xF) * 16;
                        i += 1;

                        const int imgx = ix * 8 + x;
                        const int imgy = iy * 4 + y;

                        if (imgx >= texture_width || imgy >= texture_height)
                            continue;
                        colorData[imgy*texture_width + imgx] = Color(intensity, intensity, intensity, alpha);
                    }
                }
            }
        }
    }
    else if (texture_format == 0)
    {
        for (ubyte iy = 0; iy < (texture_height/8); iy++) {
            for (ubyte ix = 0; ix < (texture_width/8); ix++) {
                for (ubyte y; y < 8; y++) {
                    for (ubyte x; x < 4; x++) {
                        ubyte intensity = glyphData[i];
                        i += 1;

                        ubyte[2] packedIntensity = [(intensity >> 4) & 0xF, (intensity & 0xF)];
                        for (int j = 0; j < 2; j++) {
                            ubyte imgx = cast(ubyte)(ix * 8 + x*2+j);
                            ubyte imgy = cast(ubyte)(ix * 8 + y);

                            if (imgx >= texture_width || imgy >= texture_height)
                                continue;
                            intensity = cast(ubyte)(packedIntensity[j]*16);
                            colorData[imgy*texture_width + imgx] = Color(intensity, intensity, intensity, intensity);
                        }
                    }
                }
            }
        }
    }
    writePng((folderName ~ "/" ~ fileName), outputImage);
}

///Takes an image and converts it into a BTI Glyph Page, currently unused cause dang there is like no straight info on how you do this
void convertImage(string imageName, string fileName, ushort texture_format, ushort texture_height, ushort texture_width) {
    MemoryImage inputImage = readPng(fileName ~ "/" ~ imageName);
    ubyte[] result, block, blockResult;
    int step;
    
    if (texture_format == 2)
    {
    	step = max(texture_width * texture_height / 4 / 8 / 100, 2048);
    } 
    else if (texture_format == 0) 
    {
    	step = max(texture_width * texture_height / 8 / 8 / 100, 2048);	
    }
}

int extractBFN(File bfn) {
    string folderName = baseName(bfn.name, ".bfn");
    if (!folderName.exists) {
        mkdir(folderName);
    } else {
		writeln("Folder already exists. Do you wish to overwrite it's contents?[y/n]");
		stdout.flush;
		if (startsWith(readln, "n")) {
			writeln("Permission denied. Exiting program...");
			return 1;
		}
    }
    //Initialize our Section Holders
    INF1Section[] inf1;
    GLY1Section[] gly1;
    MAP1Section[] map1;
    WID1Section[] wid1;
    File jsonFile = File(folderName ~ "/" ~ "data.json", "w");
    skipAmount(bfn, 12); //Skip header name & filesize
    uint blockAmount = readU32(bfn);
    skipAmount(bfn, 16); //Skip padding
    for (int i = 0; i < blockAmount; i++) {
        string section = readString(bfn, 4);
        writefln("Found %s Section", section);
        switch (section) {
            case "INF1":
                auto newINF1 = INF1Section(section, readU32(bfn), readU16(bfn), readU16(bfn), 
                    readU16(bfn), readU16(bfn), readU16(bfn), readU16(bfn), readU32(bfn));
                inf1 ~= newINF1;
                skipAmount(bfn, 8); //Skip padding
                writeln(newINF1);
                break;
            case "GLY1":
                auto newGLY1 = GLY1Section(section, readU32(bfn), readU16(bfn), readU16(bfn), readU16(bfn), 
                    readU16(bfn), readU32(bfn), readU16(bfn), readU16(bfn), readU16(bfn), readU16(bfn), readU16(bfn));
                gly1 ~= newGLY1;
                skipAmount(bfn, 2);
                const uint sheetCount = ((newGLY1.end_glyph - newGLY1.start_glyph) 
                    / (newGLY1.glyph_horizontal_count * newGLY1.glyph_vertical_count) + 1);
                writeln(newGLY1);
                for (int j = 0; j < sheetCount; j++) {
                    //Read Image Data
                    extractImage(bfn, folderName, newGLY1.page_data_size, newGLY1.texture_format, newGLY1.texture_width, 
                        newGLY1.texture_height, (format!"char_%s.png"(j)));
                }
                break;
            case "MAP1":
                auto newMAP1 = MAP1Section(section, readU32(bfn), readU16(bfn), readU16(bfn), readU16(bfn), readU16(bfn));
                writeln(newMAP1);
                switch (newMAP1.mapping_type)
                {
                    case 0:
                        skipAmount(bfn, 16);
                        break;
                    case 2:
                        for (int j = 0; j < newMAP1.mapping_entry_count; j++)
                        {
                            newMAP1.entries ~= readU16(bfn);
                        }
                        break;
                    case 3:
                        for (int j = 0; j < 2; j++)
                        {
                            for (int k = 0; k < newMAP1.mapping_entry_count; k++)
                            {
                                newMAP1.entries ~= readU16(bfn);
                            }
                        }
                        break;
                    default:
                        throw new Exception("Invalid mapping type: " ~ format!"%s"(newMAP1.mapping_type));
                }
                map1 ~= newMAP1;
                break;
            case "WID1":
                auto newWID1 = WID1Section(section, readU32(bfn), readU16(bfn), readU16(bfn));
                writeln(newWID1);
                writefln("Found %s packets", (newWID1.last_code_included - newWID1.first_code_included));
                for (int j = 0; j < (newWID1.last_code_included - newWID1.first_code_included); j++)
                {
                    newWID1.packets ~= WID1Packet(readU8(bfn), readU8(bfn));
                }
                wid1 ~= newWID1;
                break;
            default:
                throw new Exception("Unknown Section " ~ section);
        }
        while (bfn.tell() % 0x20 != 0) {
            skipAmount(bfn, 1);
        }
    }
    //Combine section data together for JSON output
    BFNInfo info = BFNInfo(inf1, gly1, map1, wid1);
    jsonFile.writeln(info.serializeToPrettyJson);
    return 0;
}

int repackBFN(string fileName) {
    string jsonFilename = fileName ~ "/" ~ "data.json";
    const string jsonData = readText(jsonFilename);
    const Json jsonInfo = parseJsonString(jsonData);
    BFNInfo bfninfo = deserializeJson!BFNInfo(jsonInfo);
    BinaryWriter writer = BinaryWriter(ByteOrder.BigEndian);
    File newBFN = File((fileName ~ "_new.bfn"), "wb");
    ubyte[] sectionBuffer;
    //Write Section Data to a separate buffer first since Header Data
    //Has to be figured out last
    //WRITE INF1 SECTION(Only the last one matters)
    writer.writeArray(cast(char[])(bfninfo.inf1[$ - 1].section_name));
    writer.write(to!uint(bfninfo.inf1[$ - 1].section_size));
    writer.write(to!ushort(bfninfo.inf1[$ - 1].encoding));
    writer.write(to!ushort(bfninfo.inf1[$ - 1].ascent));
    writer.write(to!ushort(bfninfo.inf1[$ - 1].descent));
    writer.write(to!ushort(bfninfo.inf1[$ - 1].width));
    writer.write(to!ushort(bfninfo.inf1[$ - 1].leading));
    writer.write(to!ushort(bfninfo.inf1[$ - 1].fallback_code));
    writer.write(to!uint(bfninfo.inf1[$ - 1].unk1));
    writer.writeArray(new ubyte[8]); //Padding
    //WRITE GLY1 SECTION (Assuming there is only one of these)
    writer.writeArray(cast(char[])(bfninfo.gly1[0].section_name));
    writer.write(to!uint(bfninfo.gly1[0].section_size));
    writer.write(to!ushort(bfninfo.gly1[0].start_glyph));
    writer.write(to!ushort(bfninfo.gly1[0].end_glyph));
    writer.write(to!ushort(bfninfo.gly1[0].cell_width));
    writer.write(to!ushort(bfninfo.gly1[0].cell_height));
    writer.write(to!uint(bfninfo.gly1[0].page_data_size));
    writer.write(to!ushort(bfninfo.gly1[0].texture_format));
    writer.write(to!ushort(bfninfo.gly1[0].glyph_horizontal_count));
    writer.write(to!ushort(bfninfo.gly1[0].glyph_vertical_count));
    writer.write(to!ushort(bfninfo.gly1[0].texture_width));
    writer.write(to!ushort(bfninfo.gly1[0].texture_height));
    writer.writeArray(new ubyte[2]); //Padding
    const uint sheetCount = ((bfninfo.gly1[0].end_glyph - bfninfo.gly1[0].start_glyph) / 
        (bfninfo.gly1[0].glyph_horizontal_count * bfninfo.gly1[0].glyph_vertical_count) + 1);
    for (int i = 0; i < sheetCount; i++)
    {
    	//Right now we expect end user to convert the images through other means
    	string btiFileName = fileName ~ "/" ~ "char_" ~ to!string(i) ~ ".bti";
		ubyte[] imgData = cast(ubyte[])read(btiFileName);
		writer.writeArray(imgData);
    }
    //WRITE MAP1 SECTION
    for (int i = 0; i < bfninfo.map1.length; i++)
    {
    	writer.writeArray(cast(char[])(bfninfo.map1[i].section_name));	
    	writer.write(to!uint(bfninfo.map1[i].section_size));	
    	writer.write(to!ushort(bfninfo.map1[i].mapping_type));	
    	writer.write(to!ushort(bfninfo.map1[i].first_char));	
    	writer.write(to!ushort(bfninfo.map1[i].last_char));	
    	writer.write(to!ushort(bfninfo.map1[i].mapping_entry_count));
    	if (bfninfo.map1[i].entries != null)
    	{
    		writer.write(bfninfo.map1[i].entries);
    	}
    }
    while (writer.buffer.length % 0x20 != 0)
    {
    	writer.writeArray(new ubyte[1]);
    }
    ///WRITE WID1 SECTION
    writer.writeArray(cast(char[])(bfninfo.wid1[0].section_name));
    writer.write(to!uint(bfninfo.wid1[0].section_size));
    writer.write(to!ushort(bfninfo.wid1[0].first_code_included));
    writer.write(to!ushort(bfninfo.wid1[0].last_code_included));
    for (int i = 0; i < bfninfo.wid1[0].packets.length; i++)
    {
    	writer.write(to!ubyte(bfninfo.wid1[0].packets[i].kerning));
    	writer.write(to!ubyte(bfninfo.wid1[0].packets[i].width));
    }
    ///Begin Writing to File
    BinaryWriter header = BinaryWriter(ByteOrder.BigEndian);
    header.writeArray(cast(char[])"FONTbfn1");
    header.write(to!uint(writer.buffer.length + 32));
    header.write(to!uint(bfninfo.inf1.length + bfninfo.gly1.length + bfninfo.map1.length + bfninfo.wid1.length));
    header.writeArray(new ubyte[16]);
    newBFN.rawWrite(header.buffer);
    newBFN.rawWrite(writer.buffer);
    header.clear();
    writer.clear();
    return 0;
}