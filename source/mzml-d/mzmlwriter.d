/* Tools to write mzML files from an MSXScan[]. 
 * Author: Jonathan Samson
 * Date: 03-07-2024
 */

module mzmlwriter;
import scans;
import std.bitmanip;
import std.conv;
import std.base64;
import std.stdio;
import std.math;
import std.exception;
import std.algorithm;
import dxml.writer;
import std.array : appender;
import std.format;

/**
 * Writes the information from a ReferenceableParamGroupRef object.
 * Arguments:
 *	refParamGroupRef = the object to write from
 *  content = xmlWriter appender to write to
 */
void writeReferenceableParamGroupRef(T)(ReferenceableParamGroupRef referenceableParamGroupRef, T content)
{
	content.openStartTag("referenceableParamGroupRef");
	content.writeAttr("reference", referenceableParamGroupRef.reference);
	content.closeStartTag(EmptyTag.yes);
}

/**
 * Writes the information from a CVParam object.
 * Arguments:
 *	cvParam = the object to write from
 *  content = xmlWriter appender to write to
 */
void writeCVParam(T)(CVParam cvParam, T content)
{
	content.openStartTag("cvParam");
	content.writeAttr("cvRef", cvParam.cvRef);
	content.writeAttr("accession", cvParam.accession);
	content.writeAttr("value", cvParam.value);
	content.writeAttr("name", cvParam.name);
	if(cvParam.unitCVRef != "")
	{
		content.writeAttr("unitAccession", cvParam.unit_accession);
		content.writeAttr("unitName", cvParam.unitName);
		content.writeAttr("unitCvRef", cvParam.unitCVRef);
	}
	content.closeStartTag(EmptyTag.yes);
}

/**
 * Writes the information from a UserParam object.
 * Arguments:
 *  userParam = the object to write from
 *  content = xmlWriter appender to write to
 */
void writeUserParam(T)(UserParam userParam, T content)
{
	content.openStartTag("userParam");
	content.writeAttr("type", userParam.type);
	content.writeAttr("value", userParam.value);
	content.writeAttr("name", userParam.name);
	if(userParam.unitCvRef != "")
	{
		content.writeAttr("unitAccession", userParam.unitAccession);
		content.writeAttr("unitCvRef", userParam.unitCvRef);
		content.writeAttr("unitName", userParam.unitName);
	}
	content.closeStartTag(EmptyTag.yes);
}

/**
 * Parses the MSXScan[] to generate the content for an mzML file
 * Params:
 *   scans = The array of scans to be included in the file
 *   compression = Peak list compression type - only "zlib" accepted
 *
 * Returns: the final content to be added to the mzML file
 */
string generate_mzML_content(ScanFile scan, string filename, string compression = "none")
{
	///TODO: update .mzML based on new/changed peaks/scans/etc
	auto app = appender!string();
	app.writeXMLDecl!string();
	auto content = xmlWriter(app);
	content.openStartTag("mzML");
	content.writeAttr("xmlns", "http://psi.hupo.org/ms/mzml");
	content.writeAttr("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
	content.writeAttr("xsi:schemaLocation", 
					  "http://psi.hupo.org/ms/mzml http://psidev.info/files/ms/mzML/xsd/mzML1.1.0.xsd");
	content.writeAttr("accession", scan.mzML.accession);
	content.writeAttr("id", scan.mzML.id);
	content.writeAttr("version", scan.mzML.vers);
	content.closeStartTag();
	content.openStartTag("cvList");
	content.writeAttr("count", scan.mzML.cvList.count.to!string);
	content.closeStartTag();
	for(int i=0; i<scan.mzML.cvList.count; ++i)
	{
		content.openStartTag("cv");
		content.writeAttr("id", scan.mzML.cvList.cvs[i].id);
		content.writeAttr("fullName", scan.mzML.cvList.cvs[i].fullName);
		content.writeAttr("version", scan.mzML.cvList.cvs[i].vers);
		content.writeAttr("URI", scan.mzML.cvList.cvs[i].URI);
		content.closeStartTag(EmptyTag.yes);
	}
	content.writeEndTag("cvList");
	content.openStartTag("fileDescription");
	content.closeStartTag();
	content.openStartTag("fileContent");
	content.closeStartTag();
	foreach(referenceableParamGroupRef; scan.mzML.fileDescription.fileContent.refParamRef)
	{
		writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
	}
	foreach(cvParam; scan.mzML.fileDescription.fileContent.cvParams)
	{
		writeCVParam(cvParam, &content);
	}
	foreach(userParam; scan.mzML.fileDescription.fileContent.userParams)
	{
		writeUserParam(userParam, &content);
	}
	content.writeEndTag("fileContent");
	content.openStartTag("sourceFileList");
	content.writeAttr("count", scan.mzML.fileDescription.sourceFileList.count.to!string);
	content.closeStartTag();
	for(int i=0; i<scan.mzML.fileDescription.sourceFileList.count; ++i)
	{
		content.openStartTag("sourceFile");
		content.writeAttr("id", scan.mzML.fileDescription.sourceFileList.sourceFiles[i].id);
		content.writeAttr("name", scan.mzML.fileDescription.sourceFileList.sourceFiles[i].name);
		content.writeAttr("location", scan.mzML.fileDescription.sourceFileList.sourceFiles[i].location);
		content.closeStartTag();
		foreach(referenceableParamGroupRef; scan.mzML.fileDescription.sourceFileList.sourceFiles[i].refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; scan.mzML.fileDescription.sourceFileList.sourceFiles[i].cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; scan.mzML.fileDescription.sourceFileList.sourceFiles[i].userParams)
		{
			writeUserParam(userParam, &content);
		}
		content.writeEndTag("sourceFile");
	}
	content.writeEndTag("sourceFileList");
	foreach(contact; scan.mzML.fileDescription.contacts)
	{
		content.openStartTag("contact");
		content.closeStartTag();
		foreach(referenceableParamGroupRef; contact.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; contact.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; contact.userParams)
		{
			writeUserParam(userParam, &content);
		}
		content.writeEndTag("contact");
	}
	content.writeEndTag("fileDescription");
	content.openStartTag("referenceableParamGroupList");
	content.writeAttr("count", scan.mzML.referenceableParamGroupList.count.to!string);
	content.closeStartTag();
	foreach(referenceableParamGroup; scan.mzML.referenceableParamGroupList.refParamGroups)
	{
		content.openStartTag("referenceableParamGroup");
		content.writeAttr("id", referenceableParamGroup.id);
		content.closeStartTag();
		foreach(cvParam; referenceableParamGroup.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; referenceableParamGroup.userParams)
		{
			writeUserParam(userParam, &content);
		}
		content.writeEndTag("referenceableParamGroup");
	}
	content.writeEndTag("referenceableParamGroupList");
	content.openStartTag("sampleList");
	content.writeAttr("count", scan.mzML.sampleList.count.to!string);
	content.closeStartTag();
	foreach(sample; scan.mzML.sampleList.samples)
	{
		content.openStartTag("sample");
		content.writeAttr("id", sample.id);
		content.writeAttr("name", sample.name);
		content.closeStartTag();
		foreach(referenceableParamGroupRef; sample.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; sample.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; sample.userParams)
		{
			writeUserParam(userParam, &content);
		}
		content.writeEndTag("sample");
	}
	content.writeEndTag("sampleList");
	content.openStartTag("softwareList");
	content.writeAttr("count", scan.mzML.softwareList.count.to!string);
	content.closeStartTag();
	foreach(software; scan.mzML.softwareList.softwares)
	{
		content.openStartTag("software");
		content.writeAttr("id", software.id);
		content.writeAttr("version", software.vers);
		content.closeStartTag();
		foreach(referenceableParamGroupRef; software.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; software.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; software.userParams)
		{
			writeUserParam(userParam, &content);
		}
		content.writeEndTag("software");
	}
	content.writeEndTag("softwareList");
	content.openStartTag("scanSettingsList");
	content.writeAttr("count", scan.mzML.scanSettingsList.count.to!string);
	content.closeStartTag();
	foreach(scanSetting; scan.mzML.scanSettingsList.scanSettings)
	{
		content.openStartTag("scanSettings");
		content.writeAttr("id", scanSetting.id);
		content.closeStartTag();
		foreach(referenceableParamGroupRef; scanSetting.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; scanSetting.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; scanSetting.userParams)
		{
			writeUserParam(userParam, &content);
		}
		if(scanSetting.sourceFileRefList.count > 0)
		{
			content.openStartTag("sourceFileRefList");
			content.writeAttr("count", scanSetting.sourceFileRefList.count.to!string);
			content.closeStartTag();
			foreach(sourceFileRef; scanSetting.sourceFileRefList.sourceFileRefs)
			{
				content.openStartTag("sourceFileRef");
				content.writeAttr("reference", sourceFileRef.reference);
				content.closeStartTag(EmptyTag.yes);
			}
			content.writeEndTag("sourceFileRefList");
		}
		if(scanSetting.targetList.count > 0)
		{
			content.openStartTag("targetList");
			content.writeAttr("count", scanSetting.targetList.count.to!string);
			content.closeStartTag();
			foreach(target; scanSetting.targetList.targets)
			{
				content.openStartTag("target");
				content.closeStartTag();
				foreach(referenceableParamGroupRef; target.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; target.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; target.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.writeEndTag("target");
			}
		}
		content.writeEndTag("scanSettings");
	}
	content.writeEndTag("scanSettingsList");
	content.openStartTag("instrumentConfigurationList");
	content.writeAttr("count", scan.mzML.instrumentConfigurationList.count.to!string);
	content.closeStartTag();
	foreach(instrumentConfiguration; scan.mzML.instrumentConfigurationList.instrumentConfigurations)
	{
		content.openStartTag("instrumentConfiguration");
		content.writeAttr("id", instrumentConfiguration.id);
		if(instrumentConfiguration.scanSettingsRef != "")
		{
			content.writeAttr("scanSettingsRef", instrumentConfiguration.scanSettingsRef);
		}
		content.closeStartTag();
		foreach(referenceableParamGroupRef; instrumentConfiguration.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; instrumentConfiguration.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; instrumentConfiguration.userParams)
		{
			writeUserParam(userParam, &content);
		}
		if(instrumentConfiguration.componentList.count > 0)
		{
			content.openStartTag("componentList");
			content.writeAttr("count", instrumentConfiguration.componentList.count.to!string);
			content.closeStartTag();
			foreach(source; instrumentConfiguration.componentList.sources)
			{
				content.openStartTag("source");
				content.writeAttr("order", source.order.to!string);
				content.closeStartTag();
				foreach(referenceableParamGroupRef; source.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; source.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; source.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.writeEndTag("source");
			}
			foreach(analyzer; instrumentConfiguration.componentList.analyzers)
			{
				content.openStartTag("analyzer");
				content.writeAttr("order", analyzer.order.to!string);
				content.closeStartTag();
				foreach(referenceableParamGroupRef; analyzer.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; analyzer.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; analyzer.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.writeEndTag("analyzer");
			}
			foreach(detector; instrumentConfiguration.componentList.detectors)
			{
				content.openStartTag("detector");
				content.writeAttr("order", detector.order.to!string);
				content.closeStartTag();
				foreach(referenceableParamGroupRef; detector.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; detector.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; detector.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.writeEndTag("detector");
			}
			content.writeEndTag("componentList");
		}
		if(instrumentConfiguration.softwareRef.reference != "")
		{
			content.openStartTag("softwareRef");
			content.writeAttr("reference", instrumentConfiguration.softwareRef.reference);
			content.closeStartTag(EmptyTag.yes);
		}
		content.writeEndTag("instrumentConfiguration");
	}
	content.writeEndTag("instrumentConfigurationList");
	content.openStartTag("dataProcessingList");
	content.writeAttr("count", scan.mzML.dataProcessingList.count.to!string);
	content.closeStartTag();
	foreach(dataProcessing; scan.mzML.dataProcessingList.dataProcessings)
	{
		content.openStartTag("dataProcessing");
		content.writeAttr("id", dataProcessing.id);
		content.closeStartTag();
		foreach(processingMethod; dataProcessing.processingMethods)
		{
			content.openStartTag("processingMethod");
			content.writeAttr("order", processingMethod.order.to!string);
			content.writeAttr("softwareRef", processingMethod.softwareRef);
			content.closeStartTag();
			foreach(referenceableParamGroupRef; processingMethod.refParamRef)
			{
				writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
			}
			foreach(cvParam; processingMethod.cvParams)
			{
				writeCVParam(cvParam, &content);
			}
			foreach(userParam; processingMethod.userParams)
			{
				writeUserParam(userParam, &content);
			}
			content.writeEndTag("processingMethod");
		}
		content.writeEndTag("dataProcessing");
	}
	content.writeEndTag("dataProcessingList");
	content.openStartTag("run");
	content.writeAttr("defaultInstrumentConfigurationRef", scan.mzML.run.defaultInstrumentConfigurationRef);
	if(scan.mzML.run.defaultSourceFileRef != "")
	{
		content.writeAttr("defaultSourceFileRef", scan.mzML.run.defaultSourceFileRef);
	}
	content.writeAttr("id", scan.mzML.run.id);
	if(scan.mzML.run.sampleRef != "")
	{
		content.writeAttr("sampleRef", scan.mzML.run.sampleRef);
	}
	content.writeAttr("startTimeStamp", scan.mzML.run.startTimeStamp);
	content.closeStartTag();
	foreach(referenceableParamGroupRef; scan.mzML.run.refParamRef)
	{
		writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
	}
	foreach(cvParam; scan.mzML.run.cvParams)
	{
		writeCVParam(cvParam, &content);
	}
	foreach(userParam; scan.mzML.run.userParams)
	{
		writeUserParam(userParam, &content);
	}
	content.openStartTag("spectrumList");
	content.writeAttr("count", to!string(scan.mzML.run.spectrumList.count));
	content.writeAttr("defaultDataProcessingRef", scan.mzML.run.spectrumList.defaultDataProcessingRef);
	content.closeStartTag();
	foreach(spectrum; scan.mzML.run.spectrumList.spectra)
	{
		content.openStartTag("spectrum");
		content.writeAttr("index", spectrum.index.to!string);
		content.writeAttr("id", spectrum.id);
		content.writeAttr("defaultArrayLength", spectrum.defaultArrayLength.to!string);
		if(spectrum.dataProcessingRef != "")
		{
			content.writeAttr("dataProcessingRef", spectrum.dataProcessingRef);
		}
		if(spectrum.sourceFileRef != "")
		{
			content.writeAttr("sourceFileRef", spectrum.sourceFileRef);
		}
		if(spectrum.spotID != "")
		{
			content.writeAttr("spotID", spectrum.spotID);
		}
		content.closeStartTag();
		foreach(referenceableParamGroupRef; spectrum.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; spectrum.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; spectrum.userParams)
		{
			writeUserParam(userParam, &content);
		}
		if(spectrum.scanList.count > 0)
		{
			content.openStartTag("scanList");
			content.writeAttr("count", spectrum.scanList.count.to!string);
			content.closeStartTag();
			foreach(myScan; spectrum.scanList.scans)
			{
				content.openStartTag("scan");
				if(myScan.externalSpectrumID ~= "")
				{
					content.writeAttr("externalSpectrumID", myScan.externalSpectrumID);
				}
				if(myScan.instrumentConfigurationRef != "")
				{
					content.writeAttr("instrumentConfigurationRef", myScan.instrumentConfigurationRef);
				}
				if(myScan.sourceFileRef != "")
				{
					content.writeAttr("sourceFileRef", myScan.sourceFileRef);
				}
				if(myScan.spectrumRef ~= "")
				{
					content.writeAttr("spectrumRef", myScan.spectrumRef);
				}
				content.closeStartTag();
				foreach(referenceableParamGroupRef; myScan.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; myScan.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; myScan.userParams)
				{
					writeUserParam(userParam, &content);
				}
				if(myScan.scanWindowList.count > 0)
				{
					content.openStartTag("scanWindowList");
					content.writeAttr("count", myScan.scanWindowList.count.to!string);
					content.closeStartTag();
					foreach(scanWindow; myScan.scanWindowList.scanWindows)
					{
						content.openStartTag("scanWindow");
						foreach(referenceableParamGroupRef; scanWindow.refParamRef)
						{
							writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
						}
						foreach(cvParam; scanWindow.cvParams)
						{
							writeCVParam(cvParam, &content);
						}
						foreach(userParam; scanWindow.userParams)
						{
							writeUserParam(userParam, &content);
						}
						content.writeEndTag("scanWindow");
					}
					content.writeEndTag("ScanWindowList");
				}
				content.writeEndTag("scan");
			}
			content.writeEndTag("scanList");
		}
		if(spectrum.precursorList.count > 0)
		{
			content.openStartTag("precursorList");
			content.writeAttr("count", spectrum.precursorList.count.to!string);
			content.closeStartTag();
			foreach(precursor; spectrum.precursorList.precursors)
			{
				content.openStartTag("precursor");
				if(precursor.externalSpectrumID ~= "")
				{
					content.writeAttr("externalSpectrumID", precursor.externalSpectrumID);
				}
				if(precursor.sourceFileRef ~= "")
				{
					content.writeAttr("sourceFileRef", precursor.sourceFileRef);
				}
				if(precursor.spectrumRef ~= "")
				{
					content.writeAttr("spectrumRef", precursor.spectrumRef);
				}
				content.closeStartTag();
				if(precursor.isolationWindow !is null)
				{
					content.openStartTag("isolationWindow");
					content.closeStartTag();
					foreach(referenceableParamGroupRef; precursor.isolationWindow.refParamRef)
					{
						writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
					}
					foreach(cvParam; precursor.isolationWindow.cvParams)
					{
						writeCVParam(cvParam, &content);
					}
					foreach(userParam; precursor.isolationWindow.userParams)
					{
						writeUserParam(userParam, &content);
					}
					content.writeEndTag("isolationWindow");
				}
				if(precursor.selectedIonList.count > 0)
				{
					content.openStartTag("selectedIonList");
					content.writeAttr("count", precursor.selectedIonList.count.to!string);
					content.closeStartTag();
					foreach(selectedIon; precursor.selectedIonList.selectedIons)
					{
						content.openStartTag("selectedIon");
						content.closeStartTag();
						foreach(referenceableParamGroupRef; selectedIon.refParamRef)
						{
							writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
						}
						foreach(cvParam; selectedIon.cvParams)
						{
							writeCVParam(cvParam, &content);
						}
						foreach(userParam; selectedIon.userParams)
						{
							writeUserParam(userParam, &content);
						}
						content.writeEndTag("selectedIon");
					}
					content.writeEndTag("selectedIonList");
				}
				content.openStartTag("activation");
				content.closeStartTag();
				foreach(referenceableParamGroupRef; precursor.activation.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; precursor.activation.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; precursor.activation.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.writeEndTag("activation");
				content.writeEndTag("precursor");
			}
			content.writeEndTag("precursorList");
		}
		if(spectrum.productList.count > 0)
		{
			content.openStartTag("productList");
			content.writeAttr("count", spectrum.productList.count.to!string);
			content.closeStartTag();
			foreach(product; spectrum.productList.products)
			{
				content.openStartTag("product");
				content.closeStartTag();
				content.openStartTag("isolationWindow");
				content.closeStartTag();
				foreach(referenceableParamGroupRef; product.isolationWindow.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; product.isolationWindow.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; product.isolationWindow.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.writeEndTag("isolationWindow");
				content.writeEndTag("product");
			}
			content.writeEndTag("productList");
		}
		if(spectrum.binaryDataArrayList.count > 0)
		{
			content.openStartTag("binaryDataArrayList");
			content.writeAttr("count", spectrum.binaryDataArrayList.count.to!string);
			content.closeStartTag();
			foreach(binaryDataArray; spectrum.binaryDataArrayList.binaryDataArrays)
			{
				content.openStartTag("binaryDataArray");
				if(binaryDataArray.arrayLength > 0)
				{
					content.writeAttr("arrayLength", binaryDataArray.arrayLength.to!string);
				}
				if(binaryDataArray.dataProcessingRef != "")
				{
					content.writeAttr("dataProcessingRef", binaryDataArray.dataProcessingRef);
				}
				content.writeAttr("encodedLength", binaryDataArray.encodedLength.to!string);
				content.closeStartTag();
				foreach(referenceableParamGroupRef; binaryDataArray.refParamRef)
				{
					writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
				}
				foreach(cvParam; binaryDataArray.cvParams)
				{
					writeCVParam(cvParam, &content);
				}
				foreach(userParam; binaryDataArray.userParams)
				{
					writeUserParam(userParam, &content);
				}
				content.openStartTag("binary");
				content.closeStartTag();
				content.writeText(binaryDataArray.binary.encodedData, Newline.no);
				content.writeEndTag("binary", Newline.no);
				content.writeEndTag("binaryDataArray");
			}
			content.writeEndTag("binaryDataArrayList");
		}
		content.writeEndTag("spectrum");
	}
	content.writeEndTag("spectrumList");
	content.openStartTag("chromatogramList");
	content.writeAttr("count", scan.mzML.run.chromatogramList.count.to!string);
	content.writeAttr("defaultDataProcessingRef", scan.mzML.run.chromatogramList.defaultDataProcessingRef);
	content.closeStartTag();
	foreach(chromatogram; scan.mzML.run.chromatogramList.chromatograms)
	{
		content.openStartTag("chromatogram");
		content.writeAttr("index", chromatogram.index.to!string);
		content.writeAttr("id", chromatogram.id);
		content.writeAttr("defaultArrayLength", chromatogram.defaultArrayLength.to!string);
		if(chromatogram.dataProcessingRef != "")
		{
			content.writeAttr("dataProcessingRef", chromatogram.dataProcessingRef);
		}
		content.closeStartTag();
		foreach(referenceableParamGroupRef; chromatogram.refParamRef)
		{
			writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
		}
		foreach(cvParam; chromatogram.cvParams)
		{
			writeCVParam(cvParam, &content);
		}
		foreach(userParam; chromatogram.userParams)
		{
			writeUserParam(userParam, &content);
		}
		content.openStartTag("binaryDataArrayList");
		content.writeAttr("count", chromatogram.binaryDataArrayList.count.to!string);
		content.closeStartTag();
		foreach(binaryDataArray; chromatogram.binaryDataArrayList.binaryDataArrays)
		{
			content.openStartTag("binaryDataArray");
			if(binaryDataArray.arrayLength > 0)
			{
				content.writeAttr("arrayLength", binaryDataArray.arrayLength.to!string);
			}
			if(binaryDataArray.dataProcessingRef != "")
			{
				content.writeAttr("dataProcessingRef", binaryDataArray.dataProcessingRef);
			}
			content.writeAttr("encodedLength", binaryDataArray.encodedLength.to!string);
			content.closeStartTag();
			foreach(referenceableParamGroupRef; binaryDataArray.refParamRef)
			{
				writeReferenceableParamGroupRef(referenceableParamGroupRef, &content);
			}
			foreach(cvParam; binaryDataArray.cvParams)
			{
				writeCVParam(cvParam, &content);
			}
			foreach(userParam; binaryDataArray.userParams)
			{
				writeUserParam(userParam, &content);
			}
			content.openStartTag("binary");
			content.closeStartTag();
			content.writeText(binaryDataArray.binary.encodedData, Newline.no);
			content.writeEndTag("binary", Newline.no);
			content.writeEndTag("binaryDataArray");
		}
		content.writeEndTag("binaryDataArrayList");
		content.writeEndTag("chromatogram");
	}
	content.writeEndTag("chromatogramList");
	content.writeEndTag("run");
	content.writeEndTag("mzML");
	return content.output.data;
}


/* OLD; REMOVE
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", scan.chromatogram_accessions[i]);
		content.writeAttr("name", scan.chromatogram_names[i]);
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("binaryDataArrayList");
		content.writeAttr("count", "3");
		content.closeStartTag();
		content.openStartTag("binaryDataArray");
		string encoded_tic_time = encode_real_array(scan.tic_times, 
				compression,
				32);
		content.writeAttr("encodedLength", encoded_tic_time.length.to!string);
		content.closeStartTag();
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", "MS:1000521");
		content.writeAttr("name", "32-bit float");
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		if(compression == "none")
		{
			content.writeAttr("accession", "MS:1000576");
			content.writeAttr("name", "no compression");
		}
		else if (compression == "zlib")
		{
			content.writeAttr("accession", "MS:1000574");
			content.writeAttr("name", "zlib compression");
		}
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", "MS:1000595");
		content.writeAttr("name", "time array");
		content.writeAttr("value", "");
		content.writeAttr("unitCvRef", "UO");
		content.writeAttr("unitAccession", "UO:0000031");
		content.writeAttr("unitName", "minute");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("binary");
		content.closeStartTag();
		content.writeText(encoded_tic_time, Newline.no);
		content.writeEndTag("binary", Newline.no);		
		content.writeEndTag("binaryDataArray");
		content.openStartTag("binaryDataArray");
		string encoded_tic_intensity = encode_real_array(scans.tic_intensities, 
				compression=compression);
		content.writeAttr("encodedLength", encoded_tic_intensity.length.to!string);
		content.closeStartTag();
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", "MS:1000521");
		content.writeAttr("name", "32-bit float");
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		if(compression == "none")
		{
			content.writeAttr("accession", "MS:1000576");
			content.writeAttr("name", "no compression");
		}
		else if (compression == "zlib")
		{
			content.writeAttr("accession", "MS:1000574");
			content.writeAttr("name", "zlib compression");
		}
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", "MS:1000515");
		content.writeAttr("name", "intensity array");
		content.writeAttr("value", "");
		content.writeAttr("unitCvRef", "MS");
		content.writeAttr("unitAccession", "MS:1000131");
		content.writeAttr("unitName", "number of detector counts");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("binary");
		content.closeStartTag();
		content.writeText(encoded_tic_intensity, Newline.no);
		content.writeEndTag("binary", Newline.no);		
		content.writeEndTag("binaryDataArray");
		string encoded_tic_level = encode_real_array(scans.tic_levels, // is int different?
				compression,
				64);
		content.openStartTag("binaryDataArray");
		content.writeAttr("arrayLength", scans.tic_levels.length.to!string);
		content.writeAttr("encodedLength", encoded_tic_level.length.to!string);
		content.closeStartTag();
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", "MS:1000522");
		content.writeAttr("name", "64-bit integer");
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		if(compression == "none")
		{
			content.writeAttr("accession", "MS:1000576");
			content.writeAttr("name", "no compression");
		}
		else if (compression == "zlib")
		{
			content.writeAttr("accession", "MS:1000574");
			content.writeAttr("name", "zlib compression");
		}
		content.writeAttr("value", "");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("cvParam");
		content.writeAttr("cvRef", "MS");
		content.writeAttr("accession", "MS:1000786");
		content.writeAttr("name", "non-standard data array");
		content.writeAttr("value", "ms level");
		content.writeAttr("unitCvRef", "UO");
		content.writeAttr("unitAccession", "UO:0000186");
		content.writeAttr("unitName", "dimensionless unit");
		content.closeStartTag(EmptyTag.yes);
		content.openStartTag("binary");
		content.closeStartTag();
		content.writeText(encoded_tic_level, Newline.no);
		content.writeEndTag("binary", Newline.no);		
		content.writeEndTag("binaryDataArray");
		content.writeEndTag("binaryDataArrayList");
		content.writeEndTag("chromatogram");
	}
	content.writeEndTag("chromatogramList");
	content.writeEndTag("run");
	content.writeEndTag("mzML");
	content.openStartTag("indexList");
	content.writeAttr("count", "2");
	content.closeStartTag();
	content.openStartTag("index");
	content.writeAttr("name", "spectrum");
	content.closeStartTag();
	foreach(scan_number; scans.scans)
	{
		content.openStartTag("offset");
		content.writeAttr("idRef", "controllerType=0, controllerNumber=1, scan=" ~
				scan_number.scan_number.to!string);
		content.closeStartTag;
		content.writeText("offsetnotcalculated", Newline.no); // figure out how to calcualte offset (if even  possible)
		content.writeEndTag("offset");
	}
	content.writeEndTag("index");
	content.openStartTag("index");
	content.writeAttr("name", "chromatogram");
	content.closeStartTag();
	for(int i=0; i<scans.chromatogram_ids.length; ++i)
	{
		content.openStartTag("offset");
		content.writeAttr("idRef", scans.chromatogram_ids[i]);
		content.closeStartTag();
		content.writeText("offsetnotcalculated", Newline.no); // figure out how to calculate offset (if even possible)
		content.writeEndTag("offset");
	}
	content.writeEndTag("index");
	content.writeEndTag("indexList");
	content.openStartTag("indexListOffset");
	content.closeStartTag();
	content.writeText("offsetnotcalculated", Newline.no); // figure out how  to calculate offset (if even possible)
	content.writeEndTag("indexListOffset");
	content.openStartTag("fileChecksum");
	content.closeStartTag();
	content.writeText("checksumnotcalculated", Newline.no); // figure out  how to calculate checksum and include it
	content.writeEndTag("fileChecksum");
	content.writeEndTag("indexedmzML");
	return content.output.data;
}
*/
unittest
{
	import std.stdio;
	writeln("testing mzML writer");
	// Unsure how to test this internally
}

/**
 * Encodes the a real array for .mzML binary format
 * Params:
 *   real_array = the array to encode
 *   compression = The type of compression (only zlib accepted)
 *   precision = The precision used to encode the string.
 *
 * Returns: the encoded peak list
 */
string encode_real_array(
		real[] real_array,
		string compression="none",
		int precision=32)
{
	string encoded_array;
	ubyte[] encoded;
	enforce(compression == "none" || compression == "zlib",
			"Invalid compression type.");
	enforce(precision == 64 || precision == 32,
			"Invalid precision.");
	foreach(entry; real_array)
	{
		if(precision == 64)
		{
			ubyte[8] entryNative = nativeToLittleEndian(to!double(entry));
			encoded ~= entryNative;
		}
		else // precision == 32
		{
			ubyte[4] entryNative = nativeToLittleEndian(to!float(entry));
			encoded ~= entryNative;
		}
	}
	if(compression == "zlib")
	{
		import std.zlib;
		encoded = cast(ubyte[]) compress(encoded);
	}
	encoded_array = Base64.encode(encoded);
	return(encoded_array);
}
