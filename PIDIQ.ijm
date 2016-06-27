
// March 15, 2016
//
// Fully automatic macro that assesses yellowing in arabidopsis
// Input
//	- Folder of plant tray images 
//	- background is soil
// Output
//	- False color image showing isolated plants and yellowed area
//	- Results table of plant and yellowed area measurements
//
// Release v0.0.1
//
//	v0.0.1 Initial Recorded Release (borrowed codebase from Brandon Hurr cucumber macro)

////////////////////////////////

// global variables
var orig = 0; 			//stores name of picture

// for getTimeString() function
var TimeString = 0;				//Date and Time for macro run

// for createTable() function
var title1 = 0;			//Name of Results Table
var f=0;					//Result Table

// for getDateTime() function
var DateTime = 0;				//Date and Time from Exif info

//for folderChoice() function
var savedir = 0;		// Directory where files will be saved
var falsecolordir = ""; // Directory to store main image with fruit highlighted
var midlinedir = "";	// Directory to store midline/skeleton images of isoloated fruit

var filecount = 0;		// how many files are there?
var jpgcount = 0;		// how many jpgs in the folder?
var folderstoprocess = newArray(1000000);	//folder names to process
var filestoprocess = newArray(1000000);		//file names to process
var filestosave = newArray(1000000);		//file names to process


// begin macro code
resetImageJ(); // clean up in case there are open windows or ROIs in manager


getTimeString(); // makes the timestring

// control structure of macro to allow in-determinate number of images to be processed.

folderChoice(); // select folder(s) for processing

do {
	createTable(); // creates the results table
	choice = getBoolean("Do you want to process another folder?");
	if (choice==0) {
		start = getTime();
		folderstoprocess = Array.trim(folderstoprocess, filecount);
		filestoprocess = Array.trim(filestoprocess, filecount);
		filestosave = Array.trim(filestosave, filecount);
		
		setBatchMode(true);
		var fp0 = 0;
		var fp1 = 0;
		
		for (z=0; z<filestoprocess.length; z++) {
			
			roiManager("reset");
			run("Clear Results");
			
			showProgress(z/filestoprocess.length);
			
			open(folderstoprocess[z]+filestoprocess[z]);
			
			
			clearScale(); // clear any scale that is present all results will be in pixels

			orig = getTitle();

			selectWindow(orig);
			
			run("Duplicate...", "title=Painted");

			selectWindow(orig);
			
			// find green area
			run("Duplicate...", "title=Green");
			
			min=newArray(3);
			max=newArray(3);
			filter=newArray(3);
			run("HSB Stack");
			run("Convert Stack to Images");
			selectWindow("Hue");
			rename("0");
			selectWindow("Saturation");
			rename("1");
			selectWindow("Brightness");
			rename("2");
			min[0]=50; //cuts out yellow spectrum for the green area calculation
			max[0]=104; //cuts out violet spectrum for the green area calculation
			filter[0]="pass";
			min[1]=0;
			max[1]=255;
			filter[1]="pass";
			min[2]=43; //cuts out very dark greens beyond typical shadows (useful for limiting bleed onto soil) for the green area calculation
			max[2]=255;
			filter[2]="pass";
			for (i=0;i<3;i++){
			 selectWindow(""+i);
			 setThreshold(min[i], max[i]);
			 run("Convert to Mask");
			 if (filter[i]=="stop")  run("Invert");
			}
			imageCalculator("AND create", "0","1");
			imageCalculator("AND create", "Result of 0","2");
			for (i=0;i<3;i++){
			 selectWindow(""+i);
			 close();
			}
			selectWindow("Result of 0");
			close();
			selectWindow("Result of Result of 0");
			rename("Green");
			
			run("8-bit");
			run("Convert to Mask");

			//correctLUT(); // correct the f'n LUT

			invertedLUT = is("Inverting LUT");
			if (invertedLUT == 1) {
				run("Invert LUT");
				run("Invert");
			}

			
			run("Analyze Particles...", "size=50-10000000000 pixel include in_situ show=Masks"); //restricts particle size for the green area to exclude tiny specks of algae and anything significantly bigger than the area you'd expect from a typical Arabidopsis rosette
			
			run("Create Selection");
			roiManager("add");
			
			selectWindow("Green");
			run("Close");
			
			selectWindow(orig);
			
			// find yellow area
			run("Duplicate...", "title=Yellow");
			min=newArray(3);
			max=newArray(3);
			filter=newArray(3);
			run("HSB Stack");
			run("Convert Stack to Images");
			selectWindow("Hue");
			rename("0");
			selectWindow("Saturation");
			rename("1");
			selectWindow("Brightness");
			rename("2");
			min[0]=33; //cuts out red spectrum for the yellow area calculation
			max[0]=50; //cuts out green spectrum for the yellow area calculation
			filter[0]="pass";
			min[1]=1;
			max[1]=255;
			filter[1]="pass";
			min[2]=134; //cuts out very dark yellows beyond typical shadows (useful for limiting bleed onto soil) for the yellow area calculation
			max[2]=255;
			filter[2]="pass";
			for (i=0;i<3;i++){
			 selectWindow(""+i);
			 setThreshold(min[i], max[i]);
			 run("Convert to Mask");
			 if (filter[i]=="stop")  run("Invert");
			}
			imageCalculator("AND create", "0","1");
			imageCalculator("AND create", "Result of 0","2");
			for (i=0;i<3;i++){
			 selectWindow(""+i);
			 close();
			}
			selectWindow("Result of 0");
			close();
			selectWindow("Result of Result of 0");
			rename("Yellow");
			
			run("8-bit"); 
			run("Convert to Mask");

			//correctLUT(); // correct the f'n LUT

			invertedLUT = is("Inverting LUT");
			if (invertedLUT == 1) {
				run("Invert LUT");
				run("Invert");
			}

			
			run("Analyze Particles...", "size=50-10000000000 pixel include in_situ show=Masks"); // restricts particle size for the yellow area to exclude most of the stained vermiculite and biocontrol
			
			run("Create Selection");

			roiManager("add");
			
			selectWindow("Yellow");
			run("Close");
			
			selectWindow("Painted");
			run("Select None");
			roiManager("select", 0); // this is "Green"
			run("Measure");	
			greenArea = getResult("Area", 0); // get area from results table
			setForegroundColor(255, 0, 0); // Outline with Red
			run("Line Width...", "line=5"); 
			run("Fill", "slice"); 
			run("Line Width...", "line=1"); // reset line
			run("Select None");
			
			roiManager("select", 1); // this is "Yellow"
			run("Measure");
			yellowArea = getResult("Area", 1); // get area from results table
			setForegroundColor(0, 0, 255);
			run("Line Width...", "line=5"); // fill with blue
			run("Fill", "slice");

			selectWindow("Painted");
			//save with false color
			saveAs("jpg", filestosave[z] + orig + "_Painted");
			close();

			//Print results for each leaf
			print(f, orig + "\t" + greenArea + "\t" + yellowArea);
			
			//reset ROIs for netting/stripes/shell diagnostics
			roiManager("reset");
								
			// close unnecessary image windows
			run("Close All"); 

			selectWindow("Results Table (results in px)");
			saveAs("Text", filestosave[z] + "Results");
			
			fp0 = folderstoprocess[z];
			if (z < (filestoprocess.length-1)) {
				fp1 = folderstoprocess[z+1];
				if (fp0 != fp1) {
					print(f, "\\Clear");
				}
			}
			
		} // end of image loop
		
			
	} // end of if statement when choice ==0
	if (choice==1) {	
		folderChoice();
	}
} while (choice==1);

exit("Finished!");	



///////////////////////////////////////////////////////////////////////////////////////////////////
//These are the functions called by the macro
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////
function resetImageJ() {

	requires("1.48d");
	// Only if needed uncomment these lines
	//run("Proxy Settings...", "proxy=webproxy-chbs.eame.syngenta.org port=8080");
	//run("Memory & Threads...", "maximum=1500 parallel=4 run");

	run("Options...", "iterations=1 count=1 edm=Overwrite");
	run("Line Width...", "line=1");
	run("Colors...", "foreground=black background=white selection=yellow");
	run("Clear Results");
	run("Close All");
	print("\\Clear");
	run("ROI Manager...");
	run("Input/Output...", "jpeg=75 gif=-1 file=.csv use_file copy_row save_column save_row");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack redirect=None decimal=3");
}
///////////////////////////////////////

///////////////////////////////////////////////////////
function folderChoice() {

	path = getDirectory("Choose a folder of images to analyze"); 

	// saves a folder for the processed images at your path with the following name
  	savedir = path+TimeString+File.separator;
 	File.makeDirectory(savedir);

	filelist = getFileList(path);
	for (z=0; z<filelist.length; z++) {
		 if (endsWith(filelist[z],"JPG")) {
			folderstoprocess[filecount] = path;
			filestoprocess[filecount] = filelist[z];
			filestosave[filecount] = savedir;
			jpgcount++;
			filecount++;
		}
		if (endsWith(filelist[z],"jpg")) {
			folderstoprocess[filecount] = path;
			filestoprocess[filecount] = filelist[z];
			filestosave[filecount] = savedir;
			jpgcount++;
			filecount++;
		}
		 if (endsWith(filelist[z],"tif")) {
			folderstoprocess[filecount] = path;
			filestoprocess[filecount] = filelist[z];
			filestosave[filecount] = savedir;
			jpgcount++;
			filecount++;
		}
		if (endsWith(filelist[z],"tiff")) {
			folderstoprocess[filecount] = path;
			filestoprocess[filecount] = filelist[z];
			filestosave[filecount] = savedir;
			jpgcount++;
			filecount++;
		}
	}
var count = (count+1);

}// end of Folderchoice Function
///////////////////////////////////////////////////////

////////////////////////////////////////
function createTable() {

	// creates a custom results table or clears the current open if open
	title1 = "Results Table (results in px)";
	title2 = "["+title1+"]";
	f = title2;
	if (isOpen(title1))
		print(f, "\\Clear");
	else
		run("Table...", "name="+title2+" width=800 height=200");
	print(f, "\\Headings:File\tGreenArea\tYellowedArea");
} // end of function Createtable()
//////////////////////////////////////////

//////////////////////////////////////////
function getTimeString() {

// time string for folder name

MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     TimeString = DayNames[dayOfWeek]+"_";
     if (dayOfMonth<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+dayOfMonth+"_"+MonthNames[month]+"_"+year+"_";
     if (hour<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+hour+"";
     if (minute<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+minute+"_";
     if (second<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+second;

} // end of getTimeString()
//////////////////////////////////////////

///////////////////////////////////////
function clearScale() {

run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");

} // end of ClearScale () function {
///////////////////////////////////////




/////////////////////////////////////////////////////////////////////////
function correctLUT() {
	invertedLUT = is("Inverting LUT");
	if (invertedLUT == 1) {
		run("Invert LUT");
		run("Invert");
	}
}
/////////////////////////////////////////////////////////////////////////
