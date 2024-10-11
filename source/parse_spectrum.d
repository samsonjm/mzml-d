//          Copyright Jonathan Matthew Samson 2020 - 2024.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          https://www.boost.org/LICENSE_1_0.txt)

/* Parses a single spectrum from a .mzML file.
 * 
 * Author: Jonathan Samson
 * Date: 11-08-2024
 */
module parse_spectrum;
import scans;
import dxml.parser;
import std.conv;
import mzmlparser;


Spectrum parseMzmlSpectrum(T) (T range)
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
					nextSpectrum.binaryDataArrayList.binaryDataArrays ~= createBinaryDataArray(range);
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
	range.popFront();
	return nextSpectrum;
}
