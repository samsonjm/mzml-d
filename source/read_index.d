//          Copyright Jonathan Matthew Samson 2020 - 2024.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

/* Tools to parse mzML indexList.
 * 
 * Author: Jonathan Samson
 * Date: 05-03-2024
 */
module read_index;
import mzmlindex;
import dxml.parser;
import std.conv;

/**
 * Parses the indexList.
 * Params:
 *	mzML_file = The .mzML file read into a string.
 *
 * Returns: An MzMLIndex containing the parsed information
 */
MzmlIndex parse_mzml_index(
		string mzml_file)
{
	string indexType = "";
	MzmlIndex parsedIndex = new MzmlIndex;
	auto range = parseXML(mzml_file);
	range = range.skipToPath("indexList");
	range.popFront();
	while(range.front.type != EntityType.elementEnd)
	{
		auto attr = range.front.attributes;
		attr.getAttrs("name",
				&indexType);
		int[int] indexDictionary;
		int index = 0;
		range.popFront();
		while(range.front.name == "offset")
		{
			range.popFront();
			int bytePosition = range.front.text.to!int;
			indexDictionary[index] = bytePosition; //byte position
			++index;
			range.popFront();
			range.popFront();
		}
		if(indexType == "spectrum")
		{
			parsedIndex.spectrumIndex = indexDictionary;
		}
		else if(indexType == "chromatogram")
		{
			parsedIndex.chromatogramIndex = indexDictionary;
		}
		range.popFront();
	}
	return parsedIndex;
}
unittest
{
	import mzmlparser;
	string fileContents = read_file("./testfiles/mzML/tiny.pwiz.1.1.mzML");
	MzmlIndex parsedIndex = parse_mzml_index(fileContents);
	assert(parsedIndex.spectrumIndex[0] == 6883);
	assert(parsedIndex.spectrumIndex[1] == 10424);
	assert(parsedIndex.spectrumIndex[2] == 15411);
	assert(parsedIndex.spectrumIndex[3] == 16940);
	assert(parsedIndex.chromatogramIndex[0] == 20654);
	assert(parsedIndex.chromatogramIndex[1] == 22253);
}
