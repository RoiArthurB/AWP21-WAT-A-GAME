/**
 *  WAGAMA1
 *  Author: Patrick Taillandier
 *  Description: model structure definition; species definition (node agents); display definition; parameter definition; agent creation from GIS data
 */

// Name of the model
model WAGAMA1
 
global {
	// Load shapefiles
	file intersection_file <- file('../includes/nodes_simple.shp'); 
	file env_file <- file('../includes/environment.shp');
	
	// Use env_file as world shape
	geometry shape <- envelope(env_file);
	
	// Initialisation code bloc
	init {
		// Create agents 'intersection' following a shapefile
		create intersection from: intersection_file;
	}
}

// Define new agent specie called 'intersection'
species intersection {
	// Private variable
	float radius <- 2.0;
	rgb color <- #white;
	
	// Define new specie's aspect
	// (used in display)
	aspect circle {
		draw circle(radius) color: color border: #black;
	}
}

// Define new experiment
experiment with_interface type: gui {
	// Set experiment's parameters
	parameter 'GIS file of the nodes' var: intersection_file category: 'GIS';
	parameter 'GIS file of the environment' var: env_file category: 'GIS';
	
	// Define output
	output {
		// Add a display in the output
		display dynamic {
			// Display agents 'intersection' with their aspect 'circle'
			species intersection aspect: circle;
		}
	}
}