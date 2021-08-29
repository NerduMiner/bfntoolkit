import bfn;
import std.file;
import std.path;
import std.stdio;

int main(string[] args)
{
	if (args.length == 1)
	{
		throw new Exception("No arguments given. Please provide BFN/BFN Folder.");
	}
	switch (args[1]) //Operation
	{
		case "extract":
			writeln("Extracting BFN file...");
			if (args[2] != null) 
			{
				File bfn = File(args[2], "rb");
				extractBFN(bfn);
			}
			else
			{
				throw new Exception("No filename given. Please provide filename or full filepath to file");
			}
			writeln("Done!");
			break;
		case "repack":
			writeln("Repacking BFN file...");
			if (args[2] != null)
			{
				//
			}
			writeln("Done!");
			break;
		default:
			if (extension(args[1]) == ".bfn")
			{
				writeln("Extracting BFN file...");
				File bfn = File(args[1], "rb");
				extractBFN(bfn);
				writeln("Done!");
			}
			else if (!args[1].isFile())
			{
				writeln("Repacking BFN file...");
				repackBFN(args[1]);
				writeln("Done!");
			}
	}
	return 0;
}
