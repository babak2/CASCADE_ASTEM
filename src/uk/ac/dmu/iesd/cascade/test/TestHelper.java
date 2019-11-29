package uk.ac.dmu.iesd.cascade.test;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Set;
import java.util.WeakHashMap;

import repast.simphony.engine.environment.RunEnvironment;

import uk.ac.dmu.iesd.cascade.market.IBMTrader;
import uk.ac.dmu.iesd.cascade.market.ITrader;
import uk.ac.dmu.iesd.cascade.market.astem.base.ASTEMConsts;
import uk.ac.dmu.iesd.cascade.market.astem.data.ImbalData;
import uk.ac.dmu.iesd.cascade.market.data.BSOD;
import uk.ac.dmu.iesd.cascade.market.data.PxPD;
import uk.ac.dmu.iesd.cascade.agents.aggregators.BOD;
import uk.ac.dmu.iesd.cascade.base.Consts;
import uk.ac.dmu.iesd.cascade.context.CascadeContext;
import uk.ac.dmu.iesd.cascade.io.CSVWriter;


/**
 * This is a helper class for testing of CASCADE model
 * 
 * @author Babak Mahdavi Ardestani
 * @version 1.0 $ $Date: 2012/09/03
 */


public class TestHelper {
	
	static CSVWriter outputFile;

	/**
	 * This methods writes the parameters passed by arguments into CSV file format.
	 * @param fileName
	 * @param C
	 * @param NC
	 * @param B
	 * @param D
	 * @param S
	 * @param e
	 * @param k
	 */
	/*static public void writeOutput(CascadeContext mainContext, String fileName, boolean addInfoHeader, double[] valArr) {
		int [] ts_arr = new int[mainContext.ticksPerDay];

		for (int i=0; i<ts_arr.length; i++){
			ts_arr[i] = i;	
		}
		String resFileName = fileName+mainContext.getDayCount()+".csv";

		CSVWriter res = new CSVWriter(resFileName, false);

		if (addInfoHeader) {
			
			res.appendText("Random seed= "+mainContext.getRandomSeedValue());
			res.appendText("Number of Prosumers= "+mainContext.getTotalNbOfProsumers());
			res.appendText("ProfileBuildingPeriod= "+Consts.AGGREGATOR_PROFILE_BUILDING_PERIODE);
			res.appendText("TrainingPeriod= "+Consts.AGGREGATOR_TRAINING_PERIODE);
			res.appendText("REEA on?= "+Consts.AGG_RECO_REEA_ON);
			res.appendText("ColdAppliances on?= "+Consts.HHPRO_HAS_COLD_APPL);
			res.appendText("WetAppliances on?= "+Consts.HHPRO_HAS_WET_APPL);
			res.appendText("ElectSpaceHeat on?= "+Consts.HHPRO_HAS_ELEC_SPACE_HEAT);
			res.appendText("ElectWaterHeat on?= "+Consts.HHPRO_HAS_ELEC_WATER_HEAT);
			res.appendText("");
			
			res.appendText("Timeslots:");
			res.appendRow(ts_arr);
		}
		
		res.appendText("B:");
		res.appendRow(valArr);
	
		res.close(); 
		
	} */
	
	public static void writeData(double[] valArr) {
		outputFile.appendRow(valArr);
	}
	
	public static void writeText(String text) {
		outputFile.appendText(text);
	}
	
	public static void initialize(String filename) {
		
		/*if (RunEnvironment.getInstance().isBatch()) {
			try {
			    BufferedWriter outputFile = new BufferedWriter(new FileWriter(filename, true));
			} catch (IOException e) { }
			
		}
		else outputFile = new CSVWriter(filename+".csv", true); */
		
		outputFile = new CSVWriter(filename+".csv", true);

	}
	
	


}
