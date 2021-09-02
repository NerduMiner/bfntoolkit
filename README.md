# bfntoolkit
A toolkit that can extract and repack BFN font files.

# Building
bfntoolkit requires a D compiler(DMD is recommended), downloads can be found at https://dlang.org/.<br/>Once installed, run `dub build` in your CLI/Terminal in the 
root directory of the repository to compile the project.

# Usage
Run the executable in CLI/Terminal. There are two ways you can use bfntoolkit:
<br/>`bfntoolkit [filename.bfn/foldername]`
<br/>bfntoolkit can run with only your file/folder name as the argument.
<br/>`bfntoolkit [extract/repack] [filename.bfn/foldername]`
<br/>bfntoolkit can also run with an explicit command to either extract or repack, extract is used with .bfn files while repack is used with folders.

# Editing the BFN File
At this time, bfntoolkit cannot accurately reconvert the png images into the bti format specified by the bfn, you will have to use a separate tool to convert png to bti.
<br/>Wiimms Szs Tools(https://szs.wiimm.de/download.html) is recommended because wimgt can be used to quickly convert all images in a folder with the use of the 
batch command provided in the repository
<br/>The rest of the bfn data is stored inside data.json in the folder, information on the elements and sections can be found at https://wiki.cloudmodding.com/tww/BFN


Thanks to とりぽっぽ for inspiring me to make this tool.
<br/>Thanks to RenolY2 and the Editors of the CloudModding Wiki for their information on the bfn format.
<br/>Thanks to Robert Pasiński for the pack-d binary i/o library https://code.dlang.org/packages/pack-d
<br/>Thanks to Sönke Ludwig, et al. for the vibe-d json library https://code.dlang.org/packages/vibe-d
<br/>Thanks to Adam D. Ruppe for the arsd png library https://code.dlang.org/packages/arsd-official%3Apng
