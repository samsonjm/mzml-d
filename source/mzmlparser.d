//          Copyright Jonathan Matthew Samson 2020 - 2024.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

/* Tools to parse mzML files into an MzML object.
 * 
 * Author: Jonathan Samson
 * Date: 05-03-2024
 */
module mzmlparser;
import scans;
import std.bitmanip;
import std.conv;
import std.base64;
import std.stdio;
import std.math;
import std.exception;
import std.algorithm;
import dxml.parser;
import std.array;

Spectrum parseMzmlSpectrum(T)(T range)
{
	auto attr = range.front.attributes;
	Spectrum nextSpectrum = new Spectrum;
	string arrayLength;
	string index;
	attr.getAttrs("dataProcessingRef",
			&nextSpectrum.dataProcessingRef,
			"defaultArrayLength",
			&arrayLength,
			"id",
			&nextSpectrum.id,
			"index",
			&index,
			"sourceFileRef",
			&nextSpectrum.sourceFileRef,
			"spotID",
			&nextSpectrum.spotID);
	nextSpectrum.defaultArrayLength = arrayLength.to!int;
	nextSpectrum.index = index.to!uint;
	range.popFront();
	while(range.front.type != EntityType.elementEnd)
	{
		attr = range.front.attributes;
		switch(range.front.name)
		{
			case "referenceableParamGroupRef":
			{
				nextSpectrum.refParamRef ~= createReferenceableParamGroupRef(attr);
				break;
			}
			case "cvParam":
			{
				nextSpectrum.cvParams ~= createCVParam(attr);
				break;
			}
			case "userParam":
			{
				nextSpectrum.userParams ~= createUserParam(attr);
				break;
			}
			case "scanList":
			{
				string scanCount;
				attr.getAttrs("count",
						&scanCount);
				nextSpectrum.scanList.count = scanCount.to!int;
				range.popFront();
				while(range.front.type != EntityType.elementEnd)
				{
					attr = range.front.attributes;
					switch(range.front.name)
					{
						case "referenceableParamGroupRef":
						{
							nextSpectrum.scanList.refParamRef ~= createReferenceableParamGroupRef(attr);
							break;
						}
						case "cvParam":
						{
							nextSpectrum.scanList.cvParams ~= createCVParam(attr);
							break;
						}
						case "userParam":
						{
							nextSpectrum.scanList.userParams ~= createUserParam(attr);
							break;
						}
						case "scan":
						{
							Scan nextScan = new Scan;
							attr.getAttrs("externalSpectrumID",
									&nextScan.externalSpectrumID,
									"instrumentConfigurationRef",
									&nextScan.instrumentConfigurationRef,
									"sourceFileRef",
									&nextScan.sourceFileRef,
									"spectrumRef",
									&nextScan.spectrumRef);
							range.popFront();
							while(range.front.type != EntityType.elementEnd)
							{
								attr = range.front.attributes;
								switch(range.front.name)
								{
									case "referenceableParamGroupRef":
									{
										nextScan.refParamRef ~= createReferenceableParamGroupRef(attr);
										break;
									}
									case "cvParam":
									{
										nextScan.cvParams ~= createCVParam(attr);
										break;
									}
									case "userParam":
									{
										nextScan.userParams ~= createUserParam(attr);
										break;
									}
									case "scanWindowList":
									{
										string count;
										attr.getAttrs("count",
												&count);
										nextScan.scanWindowList.count = count.to!int;
										range.popFront();
										for(int k=0; k<nextScan.scanWindowList.count; ++k)
										{
											ScanWindow nextScanWindow = new ScanWindow;
											while(range.front.type != EntityType.elementEnd)
											{
												attr = range.front.attributes;
												switch(range.front.name)
												{
													case "referenceableParamGroupRef":
													{
														nextScanWindow.refParamRef ~= createReferenceableParamGroupRef(attr);
														break;
													}
													case "cvParam":
													{
														nextScanWindow.cvParams ~= createCVParam(attr);
														break;
													}
													case "userParam":
													{
														nextScanWindow.userParams ~= createUserParam(attr);
														break;
													}
													default:
													{
													}
												}
												range.popFront();
											}
											nextScan.scanWindowList.scanWindows ~= nextScanWindow;
											range.popFront();
										}
										break;
									}
									default:
									{
									}
								}
								range.popFront();
							}
							nextSpectrum.scanList.scans ~= nextScan;
							break;
						}
						default:
						{
						}
					}
					range.popFront();
				}
				break;
			}
			case "precursorList":
			{
				string count;
				attr.getAttrs("count",
						&count);
				nextSpectrum.precursorList.count = count.to!int;
				range.popFront();
				attr = range.front.attributes;
				for(int j=0; j<nextSpectrum.precursorList.count; ++j)
				{
					Precursor nextPrecursor = new Precursor;
					attr.getAttrs("externalSpectrumID",
							&nextPrecursor.externalSpectrumID,
							"sourceFileRef",
							&nextPrecursor.sourceFileRef,
							"spectrumRef",
							&nextPrecursor.spectrumRef);
					range.popFront();
					while(range.front.type != EntityType.elementEnd)
					{
						attr = range.front.attributes;
						switch(range.front.name)
						{
							case "isolationWindow":
							{
								range.popFront();
								while(range.front.type != EntityType.elementEnd)
								{
									attr = range.front.attributes;
									switch(range.front.name)
									{
										case "referenceableParamGroupRef":
										{
											nextPrecursor.isolationWindow.refParamRef ~= createReferenceableParamGroupRef(attr);
											break;
										}
										case "cvParam":
										{
											nextPrecursor.isolationWindow.cvParams ~= createCVParam(attr);
											break;
										}
										case "userParam":
										{
											nextPrecursor.isolationWindow.userParams ~= createUserParam(attr);
											break;
										}
										default:
										{
										}
									}
									range.popFront();
								}
								break;
							}
							case "selectedIonList":
							{
								string ionCount;
								attr.getAttrs("count",
										&ionCount);
								nextPrecursor.selectedIonList.count = ionCount.to!int;
								range.popFront();
								for(int k=0; k<nextPrecursor.selectedIonList.count; ++k)
								{
									SelectedIon nextSelectedIon = new SelectedIon;
									range.popFront();
									while(range.front.type != EntityType.elementEnd)
									{
										attr = range.front.attributes;
										switch(range.front.name)
										{
											case "referenceableParamGroupRef":
											{
												nextSelectedIon.refParamRef ~= createReferenceableParamGroupRef(attr);
												break;
											}
											case "cvParam":
											{
												nextSelectedIon.cvParams ~= createCVParam(attr);
												break;
											}
											case "userParam":
											{
												nextSelectedIon.userParams ~= createUserParam(attr);
												break;
											}
											default:
											{
											}
										}
										range.popFront();
									}
									nextPrecursor.selectedIonList.selectedIons ~= nextSelectedIon;
									range.popFront();
								}
								break;
							}
							case "activation":
							{
								range.popFront();
								while(range.front.type != EntityType.elementEnd)
								{
									attr = range.front.attributes;
									switch(range.front.name)
									{
										case "referenceableParamGroupRef":
										{
											nextPrecursor.activation.refParamRef ~= createReferenceableParamGroupRef(attr);
											break;
										}
										case "cvParam":
										{
											nextPrecursor.activation.cvParams ~= createCVParam(attr);
											break;
										}
										case "userParam":
										{
											nextPrecursor.activation.userParams ~= createUserParam(attr);
											break;
										}
										default:
										{
										}
									}
									range.popFront();
								}
								break;
							}
							default:
							{
							}
						}
						range.popFront();
					}
					nextSpectrum.precursorList.precursors ~= nextPrecursor;
					range.popFront();
				}
				break;
			}
			case "productList":
			{
				string count;
				attr.getAttrs("count",
						&count);
				nextSpectrum.productList.count = count.to!int;
				range.popFront();
				attr = range.front.attributes;
				for(int j=0; j<nextSpectrum.productList.count; ++j)
				{
					Product nextProduct = new Product;
					range.popFront();
					attr = range.front.attributes; // to isolationWindow
					range.popFront();
					while(range.front.type != EntityType.elementEnd)
					{
						attr = range.front.attributes;
						switch(range.front.name)
						{
							case "referenceableParamGroupRef":
							{
								nextProduct.isolationWindow.refParamRef ~= createReferenceableParamGroupRef(attr);
								break;
							}
							case "cvParam":
							{
								nextProduct.isolationWindow.cvParams ~= createCVParam(attr);
								break;
							}
							case "userParam":
							{
								nextProduct.isolationWindow.userParams ~= createUserParam(attr);
								break;
							}
							default:
							{
							}
						}
						range.popFront();
					}
					nextSpectrum.productList.products ~= nextProduct;
					range.popFront();
					attr = range.front.attributes;
				}
				break;
			}
			case "binaryDataArrayList":
			{
				string count;
				attr.getAttrs("count",
						&count);
				nextSpectrum.binaryDataArrayList.count = count.to!int;
				for(int j=0; j<nextSpectrum.binaryDataArrayList.count; ++j)
				{
					range.popFront();
					writeln("Problem area");
					writeln("binaryDataArray: " ~ range.front.name);
					writeln("EntityType: " ~ range.front.type.to!string);
					assert(range.front.type == EntityType.elementStart);
					nextSpectrum.binaryDataArrayList.binaryDataArrays ~= createBinaryDataArray(range);
				}
				writeln("Out of problem area");
				range.popFront();
				break;
			}
			default:
			{
			}
		}
		range.popFront();
	}
	range.popFront();
	return nextSpectrum;
}

/**
 * Decodes the mzML string that represents an array.
 * Params:
 *	encoded = The encoded string.
 *	compression = The type of compression (only zlib accepted).
 *	precision = The precision used to encode the string.
 *
 * Returns: The decoded array
 */
real[] decode_mzml_string(
		string encoded, 
		string compression="none", 
		int precision=32)
{
	ubyte[] decoded = Base64.decode(encoded);
	real[] output;
	int byte_size = precision / 8;
	enforce(compression == "none" || compression == "zlib" || compression == "no compression",
			"Invalid compression type: '" ~ compression ~ "'");
	enforce(precision == 64 || precision == 32,
			"Invalid precision: " ~ precision.to!string);
	if (compression=="zlib")
	{
		import std.zlib;
		decoded = cast(ubyte[]) uncompress(decoded);
	}
	for(int i = 1; i<=decoded.length/byte_size; ++i)
	{
		float readable;
		if (precision == 64)
		{
			ubyte[8] next_value = decoded[byte_size*(i-1)..
						     byte_size*i];
			readable = littleEndianToNative!double(next_value);
		}
		else // precision = 32
		{
			ubyte[4] next_value = decoded[byte_size*(i-1)..
						     byte_size*i];
			readable = littleEndianToNative!float(next_value);
		}
		output ~= readable.to!real;
	}
	return output;
}
unittest
{
	import std.stdio;
	writeln("testing .mzML parser");
	/*
	import std.algorithm;
	import std.math;
	real[real] answer = [
		51.4678:	1460.7,
		75.8275:	1671.72,
		75.8673:	1605.31,
		100.114:	1462.5,
		101.539:	1490.52,
		107.761:	1808.18,
		118.443:	1619.86,
		130.088:	37516.3,
		146.961:	1678.81,
		171.153:	1760.86,
		199.182:	35382.9,
		243.171:	107273,
		244.174:	8717.19
	];
	string line = "Qk3fDkS2lldCl6euRND28UKXvA9EyKoPQsg6lES2z/hCyxPbRLp" ~
		"QkELXhZBE4gXdQuzjCUTKe4VDAhZoRxKMVUMS9gVE0dn6QysnFUTcG4ND" ~
		"Ry59Rwo27ENzK95H0YRqQ3Qsd0YINMA=";
	real[real] function_test = decode_mzml_string(line);
	assert(isClose(function_test.keys.sort, answer.keys.sort, 0.0001));
	assert(isClose(function_test.values.sort, answer.values.sort, 0.0001));
	line = "eJwBaACX/0JN3w5EtpZXQpenrkTQ9vFCl7wPRMiqD0LIOpREts/4QssT20" ~
		"S6UJBC14WQROIF3ULs4wlEynuFQwIWaEcSjFVDEvYFRNHZ+kMrJxVE3Bu" ~
		"DQ0cufUcKNuxDcyveR9GEakN0LHdGCDTAJ+wubA==";
	function_test = decode_mzml_string(line, "zlib");
	assert(isClose(function_test.keys.sort, answer.keys.sort, 0.0001));
	assert(isClose(function_test.values.sort, answer.values.sort, 0.0001));
	line = "QEm74cAAAABAltLK4AAAAEBS9PXAAAAAQJoe3iAAAABAUveB4AAAAECZFU" ~
		"HgAAAAQFkHUoAAAABAltn/AAAAAEBZYntgAAAAQJdKEgAAAABAWvCyAAA" ~
		"AAECcQLugAAAAQF2cYSAAAABAmU9woAAAAEBgQs0AAAAAQOJRiqAAAABA" ~
		"Yl7AoAAAAECaOz9AAAAAQGVk4qAAAABAm4NwYAAAAEBo5c+gAAAAQOFG3" ~
		"YAAAABAbmV7wAAAAED6MI1AAAAAQG6FjuAAAABAwQaYAAAAAA==";
	function_test = decode_mzml_string(line, "none", 64);
	assert(isClose(function_test.keys.sort, answer.keys.sort, 0.0001));
	assert(isClose(function_test.values.sort, answer.values.sort, 0.0001));
	line = "eJxz8Nz98AADA4PDtEunHoDooC9fwfxZcvcUwPzvjWDxmaKOYDqSPagBrP" ~
		"7mfwYwP6k6AURP9xIC86M+bALTcxx2LwDRsXMSwebM9C8A8xOczoLlHwV" ~
		"2gflJcQfA9CxrewcQnZryCMyf3VwANjfj6Xkw/6HbXbC9eanVYPf9MugF" ~
		"q89r7QO76yDbDJC5AD9eO64=";
	function_test = decode_mzml_string(line, "zlib", 64);
	assert(isClose(function_test.keys.sort, answer.keys.sort, 0.0001));
	assert(isClose(function_test.values.sort, answer.values.sort, 0.0001));
	assertThrown(decode_mzml_string(line, "7z", 64));
	assertThrown(decode_mzml_string(line, "none", 5));
	*/
}

/**
 * Reads the refereceableParamGroupRef section
 * from an mzML file and returns a 
 * ReferenceableParamGroup object based on it.
 * Params:
 * 	attr = the attributes of the curent section
 *
 * Returns: The ReferenceableParamGroupRef object
 * based on the current section of the file.
 */
ReferenceableParamGroupRef createReferenceableParamGroupRef(T)(T attr)
{
	ReferenceableParamGroupRef paramGroupRef = new ReferenceableParamGroupRef;
	attr.getAttrs("ref",
		&paramGroupRef.reference);
	return paramGroupRef;
}

/**
 * Reads the cvParam section from an mzML file
 * and returns a CVParam object based on it.
 * Params:
 * 	attr = the attributes of the curent section
 *
 * Returns: The CVParam object based on the current
 * section of the file.
 */
CVParam createCVParam(T)(T attr)
{
	CVParam cvparam = new CVParam;
	attr.getAttrs("accession",
		&cvparam.accession,
		"cvRef",
		&cvparam.cvRef,
		"name",
		&cvparam.name,
		"unitAccession",
		&cvparam.unit_accession,
		"unitCvRef",
		&cvparam.unitCVRef,
		"unitName",
		&cvparam.unitName,
		"value",
		&cvparam.value);
	return cvparam;
}

/**
 * Reads the userParam section from a mzML file
 * and returns a UserParam object based on it.
 * Params:
 * 	attr = the attributes of the curent section
 *
 * Returns: The UserParam object based on the current
 * section of the file.
 */
UserParam createUserParam(T)(T attr)
{
	UserParam userParam = new UserParam;
	attr.getAttrs("name",
		&userParam.name,
		"type",
		&userParam.type,
		"unitAccession",
		&userParam.unitAccession,
		"unitCvRef",
		&userParam.unitCvRef,
		"unitName",
		&userParam.unitName,
		"value",
		&userParam.value);
	return userParam;
}

/**
 * Creates a BinaryDataArray object from the data in the mzML file.
 * Params:
 *  range = the current parsed mzML contents
 *
 * Returns: A BinaryDataArray object populated by the proper data
 */
BinaryDataArray createBinaryDataArray(T)(T range)
{
	BinaryDataArray myBinaryDataArray = new BinaryDataArray;
	auto attr = range.front.attributes;
	string arrayLength;
	string encodedLength;
	attr.getAttrs("arrayLength",
			&arrayLength,
			"dataProcessingRef",
			&myBinaryDataArray.dataProcessingRef,
			"encodedLength",
			&encodedLength);
	if(arrayLength != "")
	{
		myBinaryDataArray.arrayLength = arrayLength.to!uint;
	}
	if(encodedLength != "")
	{
		myBinaryDataArray.encodedLength = encodedLength.to!uint;
	}
	range.popFront();
	while(range.front.type != EntityType.elementEnd)
	{
		switch(range.front.name)
		{
			case "referenceableParamGroupRef":
			{
				attr = range.front.attributes;
				myBinaryDataArray.refParamRef ~= createReferenceableParamGroupRef(attr);
				break;
			}
			case "cvParam":
			{
				attr = range.front.attributes;
				myBinaryDataArray.cvParams ~= createCVParam(attr);
				break;
			}
			case "userParam":
			{
				attr = range.front.attributes;
				myBinaryDataArray.userParams ~= createUserParam(attr);
				break;
			}
			case "binary":
			{
				range.popFront();
				if(range.front.type != EntityType.elementEnd)
				{
					immutable string data = range.front.text;
					myBinaryDataArray.binary.encodedData = data;
					range.popFront();
				}
				break;
			}
			default:
			{
			}
		}
		range.popFront();
	}
	return myBinaryDataArray;
}

/**
 * Reads the file into a string.
 * Params:
 *      file_stream = The name of the file to read.
 *
 * Returns: the contents of the file.
 */
string read_file(string name_of_file)
{
    string file_contents = "";
    try
    {
        auto file = File(name_of_file, "r");
        string line;
        while ((line = file.readln()) !is null)
        {
            file_contents ~= line;
        }
        file.close();
    }
    catch(ErrnoException e)
    {
    }
    return file_contents;
}

/** 
 * Parses the contents of an .mzML file into a list of Scan objects.
 * This parser uses dxml to parse the string.
 *
 * Params:
 *	contents = the contents of a .mzML file.
 *
 * Returns: a MzML object generated by the .mzML file.
 */
ScanFile parse_mzml(string contents)
{
	ScanFile scan = new ScanFile;
	MzML mzML = new MzML;
	auto range = parseXML(contents);
	import std.stdio;
	while(range.empty == false)
	{
		stderr.writeln(range.front.name ~ " " ~ range.front.type.to!string);
		if (range.front.type == EntityType.elementStart ||
				range.front.type == EntityType.elementEmpty)
		{
			auto attr = range.front.attributes;
			switch (range.front.name)
			{
				case "mzML":
				{
					attr.getAttrs("accession",
							&mzML.accession,
							"id",
							&mzML.id,
							"version",
							&mzML.vers);
					break;
				}
				case "cvList":
				{
					string cvList_count;
					attr.getAttrs("count",
							&cvList_count);
					mzML.cvList.count = cvList_count.to!int;
					for(int i=0; i<mzML.cvList.count; ++i)
					{
						range.popFront();
						attr = range.front.attributes;
						CV nextCV = new CV;
						attr.getAttrs("id",
							&nextCV.id,
							"fullName",
							&nextCV.fullName,
							"version",
							&nextCV.vers,
							"URI",
							&nextCV.URI);
						mzML.cvList.cvs ~= nextCV;
					}
					range.popFront();
					break;
				}
				case "fileDescription":
				{
					range.popFront();
					while(range.front.type != EntityType.elementEnd)
					{
						attr = range.front.attributes;
						switch (range.front.name)
						{
							case "fileContent":
							{
								range.popFront();
								while(range.front.type != EntityType.elementEnd)
								{
									attr = range.front.attributes;
									switch (range.front.name)
									{
										case "referenceableParamGroupRef":
										{
											mzML.fileDescription.fileContent.refParamRef ~= createReferenceableParamGroupRef(attr);
											break;
										}
										case "cvParam":
										{
											mzML.fileDescription.fileContent.cvParams ~= createCVParam(attr);
											break;
										}
										case "userParam":
										{
											mzML.fileDescription.fileContent.userParams ~= createUserParam(attr);
											break;
										}
										default:
										{
										}
									}
									range.popFront();
								}
								break;
							}
							case "sourceFileList":
							{
								string myCount;
								attr.getAttrs("count",
										&myCount);
								mzML.fileDescription.sourceFileList.count =
										myCount.to!int;
								for(int i=0; i<mzML.fileDescription.sourceFileList.count; ++i)
								{
									range.popFront();
									attr = range.front.attributes;
									SourceFile nextSourceFile = new SourceFile;
									attr.getAttrs("id",
											&nextSourceFile.id,
											"location",
											&nextSourceFile.location,
											"name",
											&nextSourceFile.name);
									range.popFront();
									while(range.front.type != EntityType.elementEnd)
									{
										attr = range.front.attributes;
										switch (range.front.name)
										{
											case "referenceableParamGroupRef":
											{
												nextSourceFile.refParamRef ~= createReferenceableParamGroupRef(attr);
												break;
											}
											case "cvParam":
											{
												nextSourceFile.cvParams ~= createCVParam(attr);
												break;
											}
											case "userParam":
											{
												nextSourceFile.userParams ~= createUserParam(attr);
												break;
											}
											default:
											{
											}
										}
										range.popFront();
									}
									mzML.fileDescription.sourceFileList.sourceFiles ~= nextSourceFile;
								}
								range.popFront();
								break;
							}
							case "contact":
							{
								range.popFront();
								Contact nextContact = new Contact;
								while(range.front.type != EntityType.elementEnd)
								{
									attr = range.front.attributes;
									switch (range.front.name)
									{
										case "referenceableParamGroupRef":
										{
											nextContact.refParamRef ~= createReferenceableParamGroupRef(attr);
											break;
										}
										case "cvParam":
										{
											nextContact.cvParams ~= createCVParam(attr);
											break;
										}
										case "userParam":
										{
											nextContact.userParams ~= createUserParam(attr);
											break;
										}
										default:
										{
										}
									}
									range.popFront();
								}
								mzML.fileDescription.contacts ~= nextContact;
								break;
							}
							default:
							{
							}
						}
						range.popFront();
					}
					break;
				}
				case "referenceableParamGroupList":
				{
					string rpg_count;
					attr.getAttrs("count",
							&rpg_count);
					mzML.referenceableParamGroupList.count = rpg_count.to!uint;
					for(int i=0; i<mzML.referenceableParamGroupList.count; ++i)
					{
						range.popFront();
						attr = range.front.attributes;
						ReferenceableParamGroup nextRefParamGroup = new ReferenceableParamGroup;
						attr.getAttrs("id",
								&nextRefParamGroup.id);
						range.popFront();
						while(range.front.type != EntityType.elementEnd)
						{
							attr = range.front.attributes;
							switch (range.front.name)
							{
								case "cvParam":
								{
									nextRefParamGroup.cvParams ~= createCVParam(attr);
									break;
								}
								case "userParam":
								{
									nextRefParamGroup.userParams ~= createUserParam(attr);
									break;
								}
								default:
								{
								}
							}
							range.popFront();
						}
						mzML.referenceableParamGroupList.refParamGroups ~= nextRefParamGroup;
					}
					range.popFront();
					break;
				}
				case "sampleList":
				{
					string sample_count;
					attr.getAttrs("count",
							&sample_count);
					mzML.sampleList.count = sample_count.to!uint;
					for(int i=0; i<mzML.sampleList.count; ++i)
					{
						range.popFront();
						attr = range.front.attributes;
						Sample nextSample = new Sample;
						attr.getAttrs("id",
								&nextSample.id,
								"name",
								&nextSample.name);
						range.popFront();
						while(range.front.type != EntityType.elementEnd)
						{
							attr = range.front.attributes;
							switch (range.front.name)
							{
								case "referenceableParamGroupRef":
								{
									nextSample.refParamRef ~= createReferenceableParamGroupRef(attr);
									break;
								}
								case "cvParam":
								{
									nextSample.cvParams ~= createCVParam(attr);
									break;
								}
								case "userParam":
								{
									nextSample.userParams ~= createUserParam(attr);
									break;
								}
								default:
								{
								}
							}
							range.popFront();
						}
						mzML.sampleList.samples ~= nextSample;
					}	
					range.popFront();
					break;
				}
				case "softwareList":
				{
					string software_count;
					attr.getAttrs("count",
						&software_count);
					mzML.softwareList.count = software_count.to!int;
					for(int i=0; i<software_count.to!int; ++i)
					{
						range.popFront();
						attr = range.front.attributes();
						Software nextSoftware = new Software;
						attr.getAttrs("id",
								&nextSoftware.id,
								"version",
								&nextSoftware.vers);
						range.popFront();
						while(range.front.type != EntityType.elementEnd)
						{
							attr = range.front.attributes();
							switch (range.front.name)
							{
								case "referenceableParamGroupRef":
								{
									nextSoftware.refParamRef ~= createReferenceableParamGroupRef(attr);
								break;
								}
								case "cvParam":
								{
									nextSoftware.cvParams ~= createCVParam(attr);
									break;
								}
								case "userParam":
								{
									nextSoftware.userParams ~= createUserParam(attr);
									break;
								}
								default:
								{
								}
							}
							range.popFront();
						}
						mzML.softwareList.softwares ~= nextSoftware;
					}		
					range.popFront();
					break;
				}
				case "scanSettingsList":
				{
					string scan_settings_count;
					attr.getAttrs("count",
							&scan_settings_count);
					mzML.scanSettingsList.count = scan_settings_count.to!uint;
					for(int i=0; i<mzML.scanSettingsList.count; ++i)
					{
						ScanSettings nextScanSettings = new ScanSettings;
						range.popFront();
						attr = range.front.attributes;
						attr.getAttrs("id",
								&nextScanSettings.id);
						range.popFront();
						while(range.front.type != EntityType.elementEnd)
						{
							attr = range.front.attributes;
							switch (range.front.name)
							{
								case "referenceableParamGroupRef":
								{
									nextScanSettings.refParamRef ~= createReferenceableParamGroupRef(attr);
								break;
								}
								case "cvParam":
								{
									nextScanSettings.cvParams ~= createCVParam(attr);
									break;
								}
								case "userParam":
								{
									nextScanSettings.userParams ~= createUserParam(attr);
									break;
								}
								case "sourceFileRefList":
								{
									string sourceFileRefCount;
									attr.getAttrs("count",
											&sourceFileRefCount);
									nextScanSettings.sourceFileRefList.count = sourceFileRefCount.to!int;
									for(int j=0; j<nextScanSettings.sourceFileRefList.count; ++j)
									{
										range.popFront();
										attr = range.front.attributes;
										SourceFileRef nextSourceFileRef = new SourceFileRef;
										attr.getAttrs("ref",
												&nextSourceFileRef.reference);
										nextScanSettings.sourceFileRefList.sourceFileRefs ~= nextSourceFileRef;
									}
									range.popFront();
									break;
								}
								case "targetList":
								{
									string targetListCount;
									attr.getAttrs("count",
											&targetListCount);
									nextScanSettings.targetList.count = targetListCount.to!int;
									for(int j=0; j<nextScanSettings.targetList.count; ++j)
									{
										range.popFront();
										attr = range.front.attributes;
										Target nextTarget = new Target;
										range.popFront();
										while(range.front.type != EntityType.elementEnd)
										{
											attr = range.front.attributes;
											switch (range.front.name)
											{
												case "referenceableParamGroupRef":
												{
													nextTarget.refParamRef ~= createReferenceableParamGroupRef(attr);
												break;
												}
												case "cvParam":
												{
													nextTarget.cvParams ~= createCVParam(attr);
													break;
												}
												case "userParam":
												{
													nextTarget.userParams ~= createUserParam(attr);
													break;
												}
												default:
												{
												}
											}
											range.popFront();
										}
										nextScanSettings.targetList.targets ~= nextTarget;
									}
									range.popFront();
									break;
								}
								default:
								{
								}
							}
							range.popFront();
						}
						mzML.scanSettingsList.scanSettings ~= nextScanSettings;
					}
					range.popFront();
					break;
				}
				case "instrumentConfigurationList":
				{
					string instrumentConfigurationCount;
					attr.getAttrs("count",
							&instrumentConfigurationCount);
					mzML.instrumentConfigurationList.count = instrumentConfigurationCount.to!int;
					for(int i=0; i<mzML.instrumentConfigurationList.count; ++i)
					{
						range.popFront();
						attr = range.front.attributes;
						InstrumentConfiguration nextConfig = new InstrumentConfiguration;
						attr.getAttrs("id",
								&nextConfig.id,
								"scanSettingsRef",
						&nextConfig.scanSettingsRef);
						range.popFront();
						while(range.front.type != EntityType.elementEnd)
						{
							attr = range.front.attributes;
							switch (range.front.name)
							{
								case "referenceableParamGroupRef":
								{
									nextConfig.refParamRef ~= createReferenceableParamGroupRef(attr);
								break;
								}
								case "cvParam":
								{
									nextConfig.cvParams ~= createCVParam(attr);
									break;
								}
								case "userParam":
								{
									nextConfig.userParams ~= createUserParam(attr);
									break;
								}
								case "componentList":
								{
									string componentCount;
									attr.getAttrs("count",
											&componentCount);
									nextConfig.componentList.count = componentCount.to!int;
									for(int j=0; j<nextConfig.componentList.count; ++j)
									{
										range.popFront();
										attr = range.front.attributes;
										switch (range.front.name)
										{
											case "source":
											{
												Source nextSource = new Source;
												string order;
												attr.getAttrs("order",
														&order);
												nextSource.order = order.to!uint;
												range.popFront();
												while(range.front.type != EntityType.elementEnd)
												{
													attr = range.front.attributes;
													switch (range.front.name)
													{
														case "referenceableParamGroupRef":
														{
															nextSource.refParamRef ~= createReferenceableParamGroupRef(attr);
														break;
														}
														case "cvParam":
														{
															nextSource.cvParams ~= createCVParam(attr);
															break;
														}
														case "userParam":
														{
															nextSource.userParams ~= createUserParam(attr);
															break;
														}
														default:
														{
														}
													}
													range.popFront();
												}
												nextConfig.componentList.sources ~= nextSource;
												break;
											}
											case "analyzer":
											{
												Analyzer nextAnalyzer = new Analyzer;
												string order;
												attr.getAttrs("order",
														&order);
												nextAnalyzer.order = order.to!uint;
												range.popFront();
												while(range.front.type != EntityType.elementEnd)
												{
													attr = range.front.attributes;
													switch (range.front.name)
													{
														case "referenceableParamGroupRef":
														{
															nextAnalyzer.refParamRef ~= createReferenceableParamGroupRef(attr);
														break;
														}
														case "cvParam":
														{
															nextAnalyzer.cvParams ~= createCVParam(attr);
															break;
														}
														case "userParam":
														{
															nextAnalyzer.userParams ~= createUserParam(attr);
															break;
														}
														default:
														{
														}
													}
													range.popFront();
												}
												nextConfig.componentList.analyzers ~= nextAnalyzer;
												break;
											}
											case "detector":
											{
												Detector nextDetector = new Detector;
												string order;
												attr.getAttrs("order",
														&order);
												nextDetector.order = order.to!uint;
												range.popFront();
												while(range.front.type != EntityType.elementEnd)
												{
													attr = range.front.attributes;
													switch (range.front.name)
													{
														case "referenceableParamGroupRef":
														{
															nextDetector.refParamRef ~= createReferenceableParamGroupRef(attr);
														break;
														}
														case "cvParam":
														{
															nextDetector.cvParams ~= createCVParam(attr);
															break;
														}
														case "userParam":
														{
															nextDetector.userParams ~= createUserParam(attr);
															break;
														}
														default:
														{
														}
													}
													range.popFront();
												}
												nextConfig.componentList.detectors ~= nextDetector;
												break;
											}
											default:
											{
											}
										}
									}
									range.popFront();
									break;
								}
								case "softwareRef":
								{
									attr.getAttrs("ref",
											&nextConfig.softwareRef.reference);
									break;
								}
								default:
								{
								}
							}
							range.popFront();
						}
						mzML.instrumentConfigurationList.instrumentConfigurations ~= nextConfig;
					}
					range.popFront();
					break;
				}
				case "dataProcessingList":
				{
					string dataProcessingCount;
					attr.getAttrs("count",
							&dataProcessingCount);
					mzML.dataProcessingList.count = dataProcessingCount.to!int;
					for(int i=0; i<mzML.dataProcessingList.count; ++i)
					{
						range.popFront();
						attr = range.front.attributes;
						DataProcessing nextDataProcessing = new DataProcessing;
						attr.getAttrs("id",
								&nextDataProcessing.id);
						range.popFront();
						while(range.front.type != EntityType.elementEnd)
						{
							attr = range.front.attributes;
							ProcessingMethod nextProcessingMethod = new ProcessingMethod;
							string processingOrder;
							attr.getAttrs("order",
									&processingOrder,
									"softwareRef",
									&nextProcessingMethod.softwareRef);
							nextProcessingMethod.order = processingOrder.to!uint;
							range.popFront();
							while(range.front.type != EntityType.elementEnd)
							{
								attr = range.front.attributes;
								switch (range.front.name)
								{
									case "referenceableParamGroupRef":
									{
										nextProcessingMethod.refParamRef ~= createReferenceableParamGroupRef(attr);
									break;
									}
									case "cvParam":
									{
										nextProcessingMethod.cvParams ~= createCVParam(attr);
										break;
									}
									case "userParam":
									{
										nextProcessingMethod.userParams ~= createUserParam(attr);
										break;
									}
									default:
									{
									}
								}
								range.popFront();
							}
							nextDataProcessing.processingMethods ~= nextProcessingMethod;
							range.popFront();
						}
						mzML.dataProcessingList.dataProcessings ~= nextDataProcessing;
					}
					range.popFront();
					break;
				}
				case "run":
				{
					attr.getAttrs("id",
							&mzML.run.id,
							"defaultInstrumentConfigurationRef",
							&mzML.run.defaultInstrumentConfigurationRef,
							"defaultSourceFileRef",
							&mzML.run.defaultSourceFileRef,
							"sampleRef",
							&mzML.run.sampleRef,
							"startTimeStamp",
							&mzML.run.startTimeStamp);
					range.popFront();
					while(range.front.type != EntityType.elementEnd)
					{
						stderr.writeln("	" ~ range.front.name ~ " " ~ range.front.type.to!string);
						attr = range.front.attributes;
						switch (range.front.name)
						{
							case "referenceableParamGroupRef":
							{
								mzML.run.refParamRef ~= createReferenceableParamGroupRef(attr);
							break;
							}
							case "cvParam":
							{
								mzML.run.cvParams ~= createCVParam(attr);
								break;
							}
							case "userParam":
							{
								mzML.run.userParams ~= createUserParam(attr);
								break;
							}
							case "spectrumList":
							{
								string spectraCount;
								attr.getAttrs("count",
										&spectraCount,
										"defaultDataProcessingRef",
										&mzML.run.spectrumList.defaultDataProcessingRef);
								mzML.run.spectrumList.count = spectraCount.to!int;
								range.popFront();
								writeln("Spectrum: " ~ range.front.name);
								for(int i=0; i<mzML.run.spectrumList.count; ++i)
								{
									mzML.run.spectrumList.spectra ~= parseMzmlSpectrum(&range);
								}
								break;
							}
							case "chromatogramList":
							{
								string count;
								attr.getAttrs("count",
										&count,
										"defaultDataProcessingRef",
										&mzML.run.chromatogramList.defaultDataProcessingRef);
								mzML.run.chromatogramList.count = count.to!int;
								range.popFront();
								for(int i=0; i<mzML.run.chromatogramList.count; ++i)
								{
									attr = range.front.attributes;
									Chromatogram nextChromatogram = new Chromatogram;
									string defaultArrayLength;
									string index;
									attr.getAttrs("dataProcessingRef",
											&nextChromatogram.dataProcessingRef,
											"defaultArrayLength",
											&defaultArrayLength,
											"id",
											&nextChromatogram.id,
											"index",
											&index);
									nextChromatogram.defaultArrayLength = defaultArrayLength.to!int;
									nextChromatogram.index = index.to!uint;
									range.popFront();
									while(range.front.type != EntityType.elementEnd)
									{
										attr = range.front.attributes;
										switch(range.front.name)
										{
											case "referenceableParamGroupRef":
											{
												nextChromatogram.refParamRef ~= createReferenceableParamGroupRef(attr);
												break;
											}
											case "cvParam":
											{
												nextChromatogram.cvParams ~= createCVParam(attr);
												break;
											}
											case "userParam":
											{
												nextChromatogram.userParams ~= createUserParam(attr);
												break;
											}
											case "binaryDataArrayList":
											{
												string binaryArrayCount;
												attr.getAttrs("count",
														&binaryArrayCount);
												nextChromatogram.binaryDataArrayList.count = binaryArrayCount.to!int;
												attr = range.front.attributes;
												for(int j=0; j<nextChromatogram.binaryDataArrayList.count; ++j)
												{
													range.popFront();
													writeln("binaryDataArray: " ~ range.front.name);
													nextChromatogram.binaryDataArrayList.binaryDataArrays ~= createBinaryDataArray(&range);
												}
												range.popFront();
												break;
											}
											default:
											{
											}
										}
										range.popFront();
									}
									mzML.run.chromatogramList.chromatograms ~= nextChromatogram;
									range.popFront();
								}
								break;
							}
							default:
							{
							}
						}
						range.popFront();
					}
					break;
				}
				default:
				{
				}
			}
		}

		// Note that the following section will be removed when implementing indexedmzML
		if(range.front.type == EntityType.elementEnd &&
				range.front.name == "mzML")
		{
			break;
		}
		range.popFront();
	}
	scan.mzML = mzML;
	scan.populate_scans();
	scan.set_scan_count();
	scan.set_start_time();
	scan.set_end_time();
	return scan;
}
unittest
{
	string fileContents = read_file("./testfiles/mzML/tiny.pwiz.1.1.mzML");
	ScanFile testFile1 = parse_mzml(fileContents);
	assert(testFile1.mzML.id == "urn:lsid:psidev.info:mzML.instanceDocuments.tiny.pwiz");
	assert(testFile1.mzML.vers == "1.1.0");
	assert(testFile1.mzML.cvList.count == 2);
	assert(testFile1.mzML.cvList.cvs.length == testFile1.mzML.cvList.count);
	assert(testFile1.mzML.cvList.cvs[0].id == "MS");
	assert(testFile1.mzML.cvList.cvs[0].URI == "http://psidev.cvs.sourceforge.net/*checkout*/psidev/psi/psi-ms/mzML/controlledVocabulary/psi-ms.obo");
	assert(testFile1.mzML.cvList.cvs[0].fullName == "Proteomics Standards Initiative Mass Spectrometry Ontology");
	assert(testFile1.mzML.cvList.cvs[0].vers == "2.26.0");
	assert(testFile1.mzML.cvList.cvs[1].id == "UO");
	assert(testFile1.mzML.cvList.cvs[1].fullName == "Unit Ontology");
	assert(testFile1.mzML.cvList.cvs[1].vers == "14:07:2009");
	assert(testFile1.mzML.cvList.cvs[1].URI == "http://obo.cvs.sourceforge.net/*checkout*/obo/obo/ontology/phenotype/unit.obo");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams.length == 2);
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[0].accession == "MS:1000580");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[0].name == "MSn spectrum");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[0].value == "");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[1].accession == "MS:1000127");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[1].name == "centroid spectrum");
	assert(testFile1.mzML.fileDescription.fileContent.cvParams[1].value == "");
	assert(testFile1.mzML.fileDescription.sourceFileList.count == 3);
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles.length == testFile1.mzML.fileDescription.sourceFileList.count);
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].id == "tiny1.yep");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].name == "tiny1.yep");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].location == "file://F:/data/Exp01");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams.length == 3);
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[0].accession == "MS:1000567");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[0].name == "Bruker/Agilent YEP file");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[0].value == "");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[1].accession == "MS:1000569");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[1].name == "SHA-1");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[1].value == "1234567890123456789012345678901234567890");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[2].accession == "MS:1000771");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[2].name == "Bruker/Agilent YEP nativeID format");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[0].cvParams[2].value == "");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].id == "tiny.wiff");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].name == "tiny.wiff");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].location == "file://F:/data/Exp01");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams.length == 3);
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[0].accession == "MS:1000562");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[0].name == "ABI WIFF file");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[0].value == "");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[1].accession == "MS:1000569");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[1].name == "SHA-1");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[1].value == "2345678901234567890123456789012345678901");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[2].accession == "MS:1000770");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[2].name == "WIFF nativeID format");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[1].cvParams[2].value == "");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].id == "sf_parameters");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].name == "parameters.par");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].location == "file://C:/settings/");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams.length == 3);
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[0].accession == "MS:1000740");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[0].name == "parameter file");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[0].value == "");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[1].accession == "MS:1000569");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[1].name == "SHA-1");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[1].value == "3456789012345678901234567890123456789012");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[2].accession == "MS:1000824");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[2].name == "no nativeID format");
	assert(testFile1.mzML.fileDescription.sourceFileList.sourceFiles[2].cvParams[2].value == "");
	assert(testFile1.mzML.fileDescription.contacts.length == 1);
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams.length == 5);
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[0].accession == "MS:1000586");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[0].name == "contact name");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[0].value == "William Pennington");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[1].accession == "MS:1000590");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[1].name == "contact organization");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[1].value == "Higglesworth University");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[2].accession == "MS:1000587");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[2].name == "contact address");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[2].value == "12 Higglesworth Avenue, 12045, HI, USA");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[3].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[3].accession == "MS:1000588");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[3].name == "contact URL");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[3].value == "http://www.higglesworth.edu/");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[4].cvRef == "MS");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[4].accession == "MS:1000589");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[4].name == "contact email");
	assert(testFile1.mzML.fileDescription.contacts[0].cvParams[4].value == "wpennington@higglesworth.edu");
	assert(testFile1.mzML.referenceableParamGroupList.count == 2);
	assert(testFile1.mzML.referenceableParamGroupList.count == testFile1.mzML.referenceableParamGroupList.refParamGroups.length);
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].id == "CommonMS1SpectrumParams");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams.length == 2);
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[0].accession == "MS:1000579");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[0].name == "MS1 spectrum");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[0].value == "");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[1].accession == "MS:1000130");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[1].name == "positive scan");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[0].cvParams[1].value == "");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].id == "CommonMS2SpectrumParams");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams.length == 2);
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[0].accession == "MS:1000580");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[0].name == "MSn spectrum");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[0].value == "");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[1].accession == "MS:1000130");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[1].name == "positive scan");
	assert(testFile1.mzML.referenceableParamGroupList.refParamGroups[1].cvParams[1].value == "");
	assert(testFile1.mzML.sampleList.count == 1);
	assert(testFile1.mzML.sampleList.samples.length == testFile1.mzML.sampleList.count);
	assert(testFile1.mzML.sampleList.samples[0].id == "_x0032_0090101_x0020_-_x0020_Sample_x0020_1");
	assert(testFile1.mzML.sampleList.samples[0].name == "Sample 1");
	assert(testFile1.mzML.softwareList.count == 3);
	assert(testFile1.mzML.softwareList.count == testFile1.mzML.softwareList.softwares.length);
	assert(testFile1.mzML.softwareList.softwares[0].id == "Bioworks");
	assert(testFile1.mzML.softwareList.softwares[0].vers == "3.3.1 sp1");
	assert(testFile1.mzML.softwareList.softwares[0].cvParams.length == 1);
	assert(testFile1.mzML.softwareList.softwares[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.softwareList.softwares[0].cvParams[0].accession == "MS:1000533");
	assert(testFile1.mzML.softwareList.softwares[0].cvParams[0].name == "Bioworks");
	assert(testFile1.mzML.softwareList.softwares[0].cvParams[0].value == "");
	assert(testFile1.mzML.softwareList.softwares[1].id == "pwiz");
	assert(testFile1.mzML.softwareList.softwares[1].vers == "1.0");
	assert(testFile1.mzML.softwareList.softwares[1].cvParams.length == 1);
	assert(testFile1.mzML.softwareList.softwares[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.softwareList.softwares[1].cvParams[0].accession == "MS:1000615");
	assert(testFile1.mzML.softwareList.softwares[1].cvParams[0].name == "ProteoWizard");
	assert(testFile1.mzML.softwareList.softwares[1].cvParams[0].value == "");
	assert(testFile1.mzML.softwareList.softwares[2].id == "CompassXtract");
	assert(testFile1.mzML.softwareList.softwares[2].vers == "2.0.5");
	assert(testFile1.mzML.softwareList.softwares[2].cvParams.length == 1);
	assert(testFile1.mzML.softwareList.softwares[2].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.softwareList.softwares[2].cvParams[0].accession == "MS:1000718");
	assert(testFile1.mzML.softwareList.softwares[2].cvParams[0].name == "CompassXtract");
	assert(testFile1.mzML.softwareList.softwares[2].cvParams[0].value == "");
	assert(testFile1.mzML.scanSettingsList.count == 1);
	assert(testFile1.mzML.scanSettingsList.count == testFile1.mzML.scanSettingsList.scanSettings.length);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].id == "tiny_x0020_scan_x0020_settings");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].sourceFileRefList.count == 1);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].sourceFileRefList.count == testFile1.mzML.scanSettingsList.scanSettings[0].sourceFileRefList.sourceFileRefs.length);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].sourceFileRefList.sourceFileRefs[0].reference == "sf_parameters");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.count == 2);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.count == testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets.length);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams.length == 1);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].accession == "MS:1000744");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].name == "selected ion m/z");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].value == "1000");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[0].cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams.length == 1);
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].accession == "MS:1000744");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].name == "selected ion m/z");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].value == "1200");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.scanSettingsList.scanSettings[0].targetList.targets[1].cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.instrumentConfigurationList.count == 1);
	assert(testFile1.mzML.instrumentConfigurationList.count == testFile1.mzML.instrumentConfigurationList.instrumentConfigurations.length);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].id == "LCQ_x0020_Deca");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams.length == 2);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[0].accession == "MS:1000554");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[0].name == "LCQ Deca");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[0].value == "");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[1].accession == "MS:1000529");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[1].name == "instrument serial number");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].cvParams[1].value == "23433");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.count == 3);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.count);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources.length == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources[0].order == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources[0].cvParams.length == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources[0].cvParams[0].accession == "MS:1000398");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources[0].cvParams[0].name == "nanoelectrospray");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.sources[0].cvParams[0].value == "");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers.length == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers[0].order == 2);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers[0].cvParams.length == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers[0].cvParams[0].accession == "MS:1000082");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers[0].cvParams[0].name == "quadrupole ion trap");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.analyzers[0].cvParams[0].value == "");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors.length == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors[0].order == 3);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors[0].cvParams.length == 1);
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors[0].cvParams[0].accession == "MS:1000253");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors[0].cvParams[0].name == "electron multiplier");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].componentList.detectors[0].cvParams[0].value == "");
	assert(testFile1.mzML.instrumentConfigurationList.instrumentConfigurations[0].softwareRef.reference == "CompassXtract");
	assert(testFile1.mzML.dataProcessingList.count == 2);
	assert(testFile1.mzML.dataProcessingList.count == testFile1.mzML.dataProcessingList.dataProcessings.length);
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].id == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods.length == 1);
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].order == 1);
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].softwareRef == "CompassXtract");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams.length == 3);
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[0].accession == "MS:1000033");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[0].name == "deisotoping");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[0].value == "");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[1].accession == "MS:1000034");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[1].name == "charge deconvolution");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[1].value == "");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[2].accession == "MS:1000035");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[2].name == "peak picking");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[0].processingMethods[0].cvParams[2].value == "");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].id == "pwiz_processing");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].order == 2);
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].softwareRef == "pwiz");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].cvParams.length == 1);
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].cvParams[0].accession == "MS:1000544");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].cvParams[0].name == "Conversion to mzML");
	assert(testFile1.mzML.dataProcessingList.dataProcessings[1].processingMethods[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.id == "Experiment_x0020_1");
	assert(testFile1.mzML.run.defaultInstrumentConfigurationRef == "LCQ_x0020_Deca");
	assert(testFile1.mzML.run.sampleRef == "_x0032_0090101_x0020_-_x0020_Sample_x0020_1");
	assert(testFile1.mzML.run.startTimeStamp == "2007-06-27T15:23:45.00035");
	assert(testFile1.mzML.run.defaultSourceFileRef == "tiny1.yep");
	assert(testFile1.mzML.run.spectrumList.count == 4);
	assert(testFile1.mzML.run.spectrumList.count == testFile1.mzML.run.spectrumList.spectra.length);
	assert(testFile1.mzML.run.spectrumList.defaultDataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[0].index == 0);
	assert(testFile1.mzML.run.spectrumList.spectra[0].id == "scan=19");
	assert(testFile1.mzML.run.spectrumList.spectra[0].defaultArrayLength == 15);
	assert(testFile1.mzML.run.spectrumList.spectra[0].refParamRef[0].reference == "CommonMS1SpectrumParams");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams.length == 7);
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[0].accession == "MS:1000511");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[0].name == "ms level");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[0].value == "1");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[1].accession == "MS:1000127");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[1].name == "centroid spectrum");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].accession == "MS:1000528");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].name == "lowest observed m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].value == "400.38999999999999");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].accession == "MS:1000527");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].name == "highest observed m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].value == "1795.5599999999999");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[3].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].accession == "MS:1000504");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].name == "base peak m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].value == "445.34699999999998");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[4].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].accession == "MS:1000505");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].name == "base peak intensity");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].value == "120053");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[5].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[6].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[6].accession == "MS:1000285");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[6].name == "total ion current");
	assert(testFile1.mzML.run.spectrumList.spectra[0].cvParams[6].value == "16675500");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.count == testFile1.mzML.run.spectrumList.spectra[0].scanList.scans.length);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.cvParams.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.cvParams[0].accession == "MS:1000795");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.cvParams[0].name == "no combination");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].instrumentConfigurationRef == "LCQ_x0020_Deca");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].accession == "MS:1000016");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].name == "scan start time");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].value == "5.8905000000000003");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].unitCVRef == "UO");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].unit_accession == "UO:0000031");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[0].unitName == "minute");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[1].accession == "MS:1000512");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[1].name == "filter string");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[1].value == "+ c NSI Full ms [ 400.00-1800.00]");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[2].accession == "MS:1000616");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[2].name == "preset scan configuration");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].cvParams[2].value == "3");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.count == testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows.length);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams.length == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].accession == "MS:1000501");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].name == "scan window lower limit");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].value == "400");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].accession == "MS:1000500");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].name == "scan window upper limit");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].value == "1800");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[0].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.count == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.count == testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays.length);
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].encodedLength == 160);
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].accession == "MS:1000514");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].name == "m/z array");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[0].binary.encodedData == "AAAAAAAAAAAAAAAAAADwPwAAAAAAAABAAAAAAAAACEAAAAAAAAAQQAAAAAAAABRAAAAAAAAAGEAAAAAAAAAcQAAAAAAAACBAAAAAAAAAIkAAAAAAAAAkQAAAAAAAACZAAAAAAAAAKEAAAAAAAAAqQAAAAAAAACxA");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].encodedLength == 160);
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].accession == "MS:1000515");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].name == "intensity array");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[0].binaryDataArrayList.binaryDataArrays[1].binary.encodedData == "AAAAAAAALkAAAAAAAAAsQAAAAAAAACpAAAAAAAAAKEAAAAAAAAAmQAAAAAAAACRAAAAAAAAAIkAAAAAAAAAgQAAAAAAAABxAAAAAAAAAGEAAAAAAAAAUQAAAAAAAABBAAAAAAAAACEAAAAAAAAAAQAAAAAAAAPA/");
	assert(testFile1.mzML.run.spectrumList.spectra[1].index == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[1].id == "scan=20");
	assert(testFile1.mzML.run.spectrumList.spectra[1].defaultArrayLength == 10);
	assert(testFile1.mzML.run.spectrumList.spectra[1].refParamRef[0].reference == "CommonMS2SpectrumParams");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams.length == 7);
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[0].accession == "MS:1000511");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[0].name == "ms level");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[0].value == "2");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[1].accession == "MS:1000128");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[1].name == "profile spectrum");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].accession == "MS:1000528");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].name == "lowest observed m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].value == "320.38999999999999");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].accession == "MS:1000527");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].name == "highest observed m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].value == "1003.5599999999999");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[3].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].accession == "MS:1000504");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].name == "base peak m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].value == "456.34699999999998");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[4].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].accession == "MS:1000505");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].name == "base peak intensity");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].value == "23433");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[5].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[6].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[6].accession == "MS:1000285");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[6].name == "total ion current");
	assert(testFile1.mzML.run.spectrumList.spectra[1].cvParams[6].value == "16675500");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.count == testFile1.mzML.run.spectrumList.spectra[1].scanList.scans.length);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.cvParams.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.cvParams[0].accession == "MS:1000795");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.cvParams[0].name == "no combination");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].instrumentConfigurationRef == "LCQ_x0020_Deca");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].accession == "MS:1000016");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].name == "scan start time");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].value == "5.9904999999999999");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].unitCVRef == "UO");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].unit_accession == "UO:0000031");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[0].unitName == "minute");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[1].accession == "MS:1000512");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[1].name == "filter string");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[1].value == "+ c d Full ms2  445.35@cid35.00 [ 110.00-905.00]");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[2].accession == "MS:1000616");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[2].name == "preset scan configuration");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].cvParams[2].value == "4");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.count == testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows.length);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams.length == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].accession == "MS:1000501");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].name == "scan window lower limit");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].value == "110");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].accession == "MS:1000500");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].name == "scan window upper limit");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].value == "905");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.count == testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors.length);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].spectrumRef == "scan=19");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].accession == "MS:1000827");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].name == "isolation window target m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].value == "445.30000000000001");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].accession == "MS:1000828");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].name == "isolation window lower offset");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].value == "0.5");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[1].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].accession == "MS:1000829");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].name == "isolation window upper offset");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].value == "0.5");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].isolationWindow.cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.count == testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons.length);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].accession == "MS:1000744");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].name == "selected ion m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].value == "445.33999999999997");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[1].accession == "MS:1000042");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[1].name == "peak intensity");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[1].value == "120053");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[2].accession == "MS:1000041");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[2].name == "charge state");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].selectedIonList.selectedIons[0].cvParams[2].value == "2");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams.length == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[0].accession == "MS:1000133");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[0].name == "collision-induced dissociation");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].accession == "MS:1000045");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].name == "collision energy");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].value == "35");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].unitCVRef == "UO");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].unit_accession == "UO:0000266");
	assert(testFile1.mzML.run.spectrumList.spectra[1].precursorList.precursors[0].activation.cvParams[1].unitName == "electronvolt");

	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.count == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.count == testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays.length);
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].encodedLength == 108);
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].accession == "MS:1000514");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].name == "m/z array");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[0].binary.encodedData == "AAAAAAAAAAAAAAAAAAAAQAAAAAAAABBAAAAAAAAAGEAAAAAAAAAgQAAAAAAAACRAAAAAAAAAKEAAAAAAAAAsQAAAAAAAADBAAAAAAAAAMkA=");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].encodedLength == 108);
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].accession == "MS:1000515");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].name == "intensity array");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[1].binaryDataArrayList.binaryDataArrays[1].binary.encodedData == "AAAAAAAANEAAAAAAAAAyQAAAAAAAADBAAAAAAAAALEAAAAAAAAAoQAAAAAAAACRAAAAAAAAAIEAAAAAAAAAYQAAAAAAAABBAAAAAAAAAAEA=");
	assert(testFile1.mzML.run.spectrumList.spectra[2].index == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[2].id == "scan=21");
	assert(testFile1.mzML.run.spectrumList.spectra[2].defaultArrayLength == 0);
	assert(testFile1.mzML.run.spectrumList.spectra[2].refParamRef[0].reference == "CommonMS1SpectrumParams");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams.length == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[0].accession == "MS:1000511");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[0].name == "ms level");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[0].value == "1");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[1].accession == "MS:1000127");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[1].name == "centroid spectrum");
	assert(testFile1.mzML.run.spectrumList.spectra[2].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].userParams.length == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[2].userParams[0].name == "example");
	assert(testFile1.mzML.run.spectrumList.spectra[2].userParams[0].value == "spectrum with no data");
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.count == testFile1.mzML.run.spectrumList.spectra[2].scanList.scans.length);
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.cvParams.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.cvParams[0].accession == "MS:1000795");
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.cvParams[0].name == "no combination");
	assert(testFile1.mzML.run.spectrumList.spectra[2].scanList.cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.count == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.count == testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays.length);
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].encodedLength == 0);
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].accession == "MS:1000514");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].name == "m/z array");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[0].binary.encodedData == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].encodedLength == 0);
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].accession == "MS:1000515");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].name == "intensity array");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[2].binaryDataArrayList.binaryDataArrays[1].binary.encodedData == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].index == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[3].id == "sample=1 period=1 cycle=22 experiment=1");
	assert(testFile1.mzML.run.spectrumList.spectra[3].spotID == "A1,42x42,4242x4242");
	assert(testFile1.mzML.run.spectrumList.spectra[3].defaultArrayLength == 15);
	assert(testFile1.mzML.run.spectrumList.spectra[3].sourceFileRef == "tiny.wiff");
	assert(testFile1.mzML.run.spectrumList.spectra[3].refParamRef[0].reference == "CommonMS1SpectrumParams");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams.length == 7);
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[0].accession == "MS:1000511");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[0].name == "ms level");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[0].value == "1");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[1].accession == "MS:1000127");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[1].name == "centroid spectrum");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].accession == "MS:1000528");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].name == "lowest observed m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].value == "142.38999999999999");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].accession == "MS:1000527");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].name == "highest observed m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].value == "942.55999999999995");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[3].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].accession == "MS:1000504");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].name == "base peak m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].value == "422.42000000000002");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[4].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].accession == "MS:1000505");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].name == "base peak intensity");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].value == "42");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[5].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[6].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[6].accession == "MS:1000285");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[6].name == "total ion current");
	assert(testFile1.mzML.run.spectrumList.spectra[3].cvParams[6].value == "4200");
	assert(testFile1.mzML.run.spectrumList.spectra[3].userParams.length == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[3].userParams[0].name == "alternate source file");
	assert(testFile1.mzML.run.spectrumList.spectra[3].userParams[0].value == "to test a different nativeID format");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.count == testFile1.mzML.run.spectrumList.spectra[3].scanList.scans.length);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.cvParams.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.cvParams[0].accession == "MS:1000795");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.cvParams[0].name == "no combination");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].instrumentConfigurationRef == "LCQ_x0020_Deca");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams.length == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].accession == "MS:1000016");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].name == "scan start time");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].value == "42.049999999999997");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].unitCVRef == "UO");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].unit_accession == "UO:0000010");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[0].unitName == "second");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[1].accession == "MS:1000512");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[1].name == "filter string");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].cvParams[1].value == "+ c MALDI Full ms [100.00-1000.00]");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.count == 1);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.count == testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows.length);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams.length == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].accession == "MS:1000501");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].name == "scan window lower limit");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].value == "100");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[0].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].accession == "MS:1000500");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].name == "scan window upper limit");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].value == "1000");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[3].scanList.scans[0].scanWindowList.scanWindows[0].cvParams[1].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.count == 2);
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.count == testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays.length);
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].encodedLength == 160);
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].accession == "MS:1000514");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].name == "m/z array");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unit_accession == "MS:1000040");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitName == "m/z");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[0].binary.encodedData == "AAAAAAAAAAAAAAAAAADwPwAAAAAAAABAAAAAAAAACEAAAAAAAAAQQAAAAAAAABRAAAAAAAAAGEAAAAAAAAAcQAAAAAAAACBAAAAAAAAAIkAAAAAAAAAkQAAAAAAAACZAAAAAAAAAKEAAAAAAAAAqQAAAAAAAACxA");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].encodedLength == 160);
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams.length == 3);
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].accession == "MS:1000515");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].name == "intensity array");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].value == "");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitName == "number of counts");
	assert(testFile1.mzML.run.spectrumList.spectra[3].binaryDataArrayList.binaryDataArrays[1].binary.encodedData == "AAAAAAAALkAAAAAAAAAsQAAAAAAAACpAAAAAAAAAKEAAAAAAAAAmQAAAAAAAACRAAAAAAAAAIkAAAAAAAAAgQAAAAAAAABxAAAAAAAAAGEAAAAAAAAAUQAAAAAAAABBAAAAAAAAACEAAAAAAAAAAQAAAAAAAAPA/");
	assert(testFile1.mzML.run.chromatogramList.count == 2);
	assert(testFile1.mzML.run.chromatogramList.count == testFile1.mzML.run.chromatogramList.chromatograms.length);
	assert(testFile1.mzML.run.chromatogramList.defaultDataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].index == 0);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].id == "tic");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].defaultArrayLength == 15);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].dataProcessingRef == "CompassXtract_x0020_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].cvParams.length == 1);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].cvParams[0].accession == "MS:1000235");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].cvParams[0].name == "total ion current chromatogram");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.count == 2);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.count == testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays.length);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].encodedLength == 160);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].dataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams.length == 3);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].accession == "MS:1000595");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].name == "time array");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitCVRef == "UO");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unit_accession == "UO:0000010");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitName == "second");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[0].binary.encodedData == "AAAAAAAAAAAAAAAAAADwPwAAAAAAAABAAAAAAAAACEAAAAAAAAAQQAAAAAAAABRAAAAAAAAAGEAAAAAAAAAcQAAAAAAAACBAAAAAAAAAIkAAAAAAAAAkQAAAAAAAACZAAAAAAAAAKEAAAAAAAAAqQAAAAAAAACxA");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].encodedLength == 160);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].dataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams.length == 3);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].accession == "MS:1000515");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].name == "intensity array");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitName == "number of counts");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[0].binaryDataArrayList.binaryDataArrays[1].binary.encodedData == "AAAAAAAALkAAAAAAAAAsQAAAAAAAACpAAAAAAAAAKEAAAAAAAAAmQAAAAAAAACRAAAAAAAAAIkAAAAAAAAAgQAAAAAAAABxAAAAAAAAAGEAAAAAAAAAUQAAAAAAAABBAAAAAAAAACEAAAAAAAAAAQAAAAAAAAPA/");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].index == 1);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].id == "sic");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].defaultArrayLength == 10);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].dataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].cvParams.length == 1);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].cvParams[0].accession == "MS:1000627");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].cvParams[0].name == "selected ion current chromatogram");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.count == 2);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.count == testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays.length);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].encodedLength == 108);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].dataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams.length == 3);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[0].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[1].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].accession == "MS:1000595");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].name == "time array");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitCVRef == "UO");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unit_accession == "UO:0000010");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].cvParams[2].unitName == "second");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[0].binary.encodedData == "AAAAAAAAAAAAAAAAAADwPwAAAAAAAABAAAAAAAAACEAAAAAAAAAQQAAAAAAAABRAAAAAAAAAGEAAAAAAAAAcQAAAAAAAACBAAAAAAAAAIkA=");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].encodedLength == 108);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].dataProcessingRef == "pwiz_processing");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams.length == 3);
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].accession == "MS:1000523");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].name == "64-bit float");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[0].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].accession == "MS:1000576");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].name == "no compression");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[1].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].cvRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].accession == "MS:1000515");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].name == "intensity array");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].value == "");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitCVRef == "MS");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unit_accession == "MS:1000131");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].cvParams[2].unitName == "number of counts");
	assert(testFile1.mzML.run.chromatogramList.chromatograms[1].binaryDataArrayList.binaryDataArrays[1].binary.encodedData == "AAAAAAAAJEAAAAAAAAAiQAAAAAAAACBAAAAAAAAAHEAAAAAAAAAYQAAAAAAAABRAAAAAAAAAEEAAAAAAAAAIQAAAAAAAAABAAAAAAAAA8D8=");
}
