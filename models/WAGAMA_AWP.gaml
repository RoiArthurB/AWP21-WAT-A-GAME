/**
 *  WAGAMA16
 *  Author: patricktaillandier
 *  Description: new actions for the owner agents
 */

model WAGAMA16


global {
	
	file intersection_file <- file('../includes/nodes.shp');
	file env_file <- file('../includes/environment.shp');
	file activities_file <- file('../includes/activities.shp');
	file owners_data <- csv_file('../includes/owners_data.csv',";", true);
	file activity_type_data <- csv_file('../includes/activity_type_data.csv',";",true);
	
	string result_file <- 'results.csv';
	//current action type
	int action_type <- -1;	
	
	geometry shape <- envelope(env_file);
	
		
	int total_water_quantity -> {length(water_unit as list)};
	int clean_water_quantity -> {(water_unit as list) count (!each.polluted)};
	int polluted_water_quantity -> {(water_unit as list) count (each.polluted)};
	float mean_money -> {owner mean_of (each.money)};
	int max_money -> {owner max_of (each.money)};
	int min_money -> {owner min_of (each.money)};
	
	int input_water_quantity_north <- 20;
	int input_water_quantity_south <- 20;
	int output_water_quantity_real;
	int output_clean_water_quantity_real;
	int output_polluted_water_quantity_real;
	int output_water_quantity_wished <- 5;
	
	
	list<int> input_water_quantity_norths <- [20,15,15,20,10,20];
	list<int> input_water_quantity_souths <- [15,15,10,25,5,20];
	
	
	bool player_turn <- true;
	int nb_activity_changeable <- 5;
	int nb_repairing <- 5;
	bool save_results <- false;
	bool interactive_mode <- true;
	int turn <- 1;
	int nb_turns <- 6;
	
	int nb_turns_with_low_water;
	int nb_turns_with_polluted_water;
	int nb_dysfonction;
	
	int min_water_quantity <- 10;
	float min_water_quality <- 0.5;
	int water_quantity ;
	float water_quality;
	
	//images used for the buttons
	list<string> text_name <- [
		"repair", "change type","end of turn"
		
	]; 
	//images used for the buttons
	list<rgb> color_name <- [
		#orange, #darkblue,#gray
		
	]; 
	
	
		
	init {
		
		create intersection from: intersection_file with: (id:read("ID"), id_next:read("ID_NEXT"), source:read("SOURCE"));
		ask intersection {
			next_intersection <- intersection first_with (each.id = id_next);
		}
		ask intersection {
			if (source = "Yes" ) {
				nb_inputs <- 1;
			} else {
				nb_inputs <- intersection count (each.next_intersection = self);
			}
		}
		create activity_type from: activity_type_data with: (name:get("activity_type"), clean_water_input:int(get("clean_water_input")),
			polluted_water_input:int(get("polluted_water_input")),money_cost:int(get("money_cost")),clean_water_output:int(get("clean_water_output")),
			polluted_water_output:int(get("polluted_water_output")),money_earned:int(get("money_earned")),excessive_water:bool(get("excessive_water")),
			excessive_pollution:bool(get("excessive_pollution")),green_activity:bool(get("green_activity")),color:rgb(get("color")));
		ask activity_type {
			do initialize;
		}
		create activity from: activities_file with: (id:read("ID"), input_id:read("INPUT"), output_id:read("OUTPUT"), type_name:read("TYPE"));
		ask activity {
			input_node <- intersection first_with (each.id = input_id);
			output_node <- intersection first_with (each.id = output_id);
			type <- activity_type first_with (each.name = type_name) ;
		}
		do load_owners_data;
		
		if (not interactive_mode) {do water_input;}
		if (save_results) {
			save "input_water_quantity_north,input_water_quantity_south,output_water_quantity_real,output_clean_water_quantity_real,output_polluted_water_quantity_real,mean_money,max_money,min_money" type: text to: result_file;
		}
		create button with: (shape: rectangle(world.shape.width/7,world.shape.height/7) at_location {world.shape.width/3, 1.5*world.shape.height/3.0});
		create button with: (shape: rectangle(world.shape.width/7,world.shape.height/7) at_location {2* world.shape.width/3, 1.5* world.shape.height/3.0});
		create button with: (shape: rectangle(world.shape.width/7,world.shape.height/7) at_location {world.shape.width/2, 2.5* world.shape.height/3.0});
		
		
		
	}
	
	reflex player_can_play when: interactive_mode and player_turn{ 
		nb_dysfonction <- nb_dysfonction + (activity count each.dysfunction);
		if (turn <= nb_turns ) {
			do tell("You can now play: turn " + turn);
		}
		do pause;
		
	}
	
	action water_input {
		ask intersection where (each.source = "Yes") {
			create water returns: water_created {
				int  input_water_quantity;
				
				if (length(input_water_quantity_norths) > (turn - 1)) {
					input_water_quantity <- (myself.id = '1') ? input_water_quantity_norths[turn - 1] : input_water_quantity_souths[turn - 1] ;
				}
				else {
					input_water_quantity <- (myself.id = '1') ? input_water_quantity_north : input_water_quantity_south ;
				}
				
				create water_unit number: input_water_quantity{
					myself.water_units << self;
				}
			}
			do accept_water water_input: first(water_created);
		}
	}
	
	
	reflex diffusion when: not player_turn or not interactive_mode{
		ask intersection where (!(empty(each.waters))) {
			do flow;
		}
	}
	
	
	action load_owners_data {
		matrix owner_matrix <- matrix(owners_data);
		loop i from: 0 to: owner_matrix.rows - 1 {
			string id_activity <- owner_matrix[0,i];
			string id_owner <- owner_matrix[1,i];
			activity current_activity <- activity first_with (each.id = id_activity);
			if (current_activity != nil ) {
				owner current_owner <- owner first_with (each.id = id_owner);
				if (current_owner = nil) {
					create owner returns: owner_created with: (id : id_owner){
						current_owner <- self;
					}
				}
				current_activity.my_owner <- current_owner;
				current_owner.my_activities << current_activity ; 	
			}	
		}	
	}
	
	action save_outputs {
		if (save_results) {
			save [input_water_quantity_north, input_water_quantity_south, output_water_quantity_real, output_clean_water_quantity_real, 
			output_polluted_water_quantity_real,mean_money,max_money,min_money] rewrite: false type: csv to: result_file;
		}
	}
	
	
	
	action activate_act {
		button selected_but <- first(button overlapping (circle(1) at_location #user_location));
		if(selected_but != nil) {
			
			ask selected_but {
				ask button {is_selected<-false;}
				if (action_type != id) {
					if (id = 2) {
						map input_values <- user_input([choose("Are you sure to end your turn?", bool,true,[true, false])]);
			     		bool end <- bool(input_values["Are you sure to end your turn?"]);
						
						if (end) {
							player_turn <- false;
							ask world {
								do water_input;
								ask activity {is_selected <- false;}
								do resume;	
							}
						}
					} else {
						
						action_type<-id;
						is_selected<-true;
					}
				} else {
					action_type<- -1;
					is_selected<-false;
				}
				
			}
		}
	}
	
	action activity_management {
		if action_type in [0,1] {
			activity selected_activity<- first(activity overlapping (circle(1.0) at_location #user_location));
			if(selected_activity != nil) {
				ask activity {
					is_selected <- false;
					
				}
				ask selected_activity {
					is_selected <- true;
					switch action_type {
						match 0 {do repair;}
						match 1 {
							do change_type;
						}
					}
				}
			}
		}
	}	
	
}

species intersection {
	float size <- 4.0;
	rgb color <- #gray;
	string id;
	string id_next;
	string source;
	intersection next_intersection;
	list<water> waters;
	int nb_inputs;

	aspect circle {
		draw square(size) color: color border: #black;
	}

	aspect network {
		if (next_intersection != nil) {
			draw line([location, next_intersection.location]) color: #blue;
		}

	}

	action accept_water (water water_input) {
		waters << water_input;
		water_input.location <- location;
	}

	action flow {
		if (next_intersection = nil) {
			output_water_quantity_real <- 0;
			output_clean_water_quantity_real <- 0;
			output_polluted_water_quantity_real <- 0;
			
			if (not empty(waters)) {
				list<water_unit> waters_output <- waters accumulate each.water_units;
				water_quantity <- length(waters_output);
				water_quality <- water_quantity = 0 ? 0.0 : (1 - ((waters_output count each.polluted) / water_quantity));
			}
			ask waters {			
				output_water_quantity_real <- output_water_quantity_real +  quantity;
				output_clean_water_quantity_real <- output_clean_water_quantity_real + quantity_clean ;
				output_polluted_water_quantity_real <- output_polluted_water_quantity_real + quantity_polluted;
					
				ask water_units {
					do die;
				}
				do die;
				
			}
			ask world {
				do save_outputs;
				player_turn <- true;
				turn <- turn + 1;
				if not interactive_mode {do water_input;}
				if (water_quantity < min_water_quantity) {nb_turns_with_low_water <- nb_turns_with_low_water + 1;}
				if (water_quality < min_water_quality) {nb_turns_with_polluted_water <- nb_turns_with_polluted_water + 1;}
				
				if (turn > nb_turns) {
					string mess <- "End of the scenario: \nnb of turns with low water: " + nb_turns_with_low_water + "\nnb of turns with polluted water: " + nb_turns_with_polluted_water +
					 "\nnb of dysfonctional activities: " + nb_dysfonction + "\nMean money of owners: " + (owner mean_of each.money) + "\nInequality of money (gini index): " + gini (owner collect float(each.money));
						
					do tell(mess);
					
				}
			}

		} else {
			do water_merge;
			loop wAg over: waters {
				ask (activity where (each.input_node = self and !(each.dysfunction))) {
					do take_water water_in: wAg;
				}
				ask (activity where (each.output_node = self and !(each.dysfunction))) {
					do reject_water water_out: wAg;
				}
				ask next_intersection {
					do accept_water(wAg);
				}

			}
		}
		waters <- [];
	}
	
	action water_merge {
		if (length(waters) > 1) {
			create water with: (water_units: waters accumulate each.water_units) returns: water_created;
			ask waters {
				do die;
			}
			waters <- water_created;
		} 
	} 

}

		
species water {
	list<water_unit> water_units;
	int quantity -> {length(water_units)};
	int quantity_polluted -> {water_units count (each.polluted)};
	int quantity_clean -> {water_units count (!each.polluted)};
		
	aspect default {
		draw circle(5) color: #blue;
	}
	
	aspect quantity_quality{
		draw circle(quantity / 6) 
			color: rgb([255 * quantity_polluted / quantity, 0, 255 * quantity_clean / quantity]);
	}

}

species water_unit {
	bool polluted <- false;
}
	
species activity {
	string id;
	string input_id;
	string output_id;
	intersection input_node;
	intersection output_node;
	rgb color -> {dysfunction ? #red : #green};
	bool dysfunction <- false;
	activity_type type;
	owner my_owner;
	string type_name;
	bool is_selected <- false;
		
	action take_water (water water_in){
		int wished_quantity <- type.clean_water_input + type.polluted_water_input;
		int quantity<- min (water_in.quantity, wished_quantity);
		list<water_unit> water_unit_taken <- quantity among  water_in.water_units;
		water_in.water_units <- water_in.water_units - water_unit_taken;
		
		int money_lost <- min (my_owner.money, type.money_cost);
		my_owner.money <- my_owner.money - money_lost;
			
		dysfunction <- (quantity < wished_quantity) or 
			((water_unit_taken count (each.polluted)) > type.polluted_water_input) or
			(money_lost < type.money_cost);
		
		if (!dysfunction) {
			 my_owner.money <- my_owner.money + type.money_earned;
		}
		ask water_unit_taken {
			do die;
		}
	}
		
	action reject_water (water water_out) {
		create water_unit number: type.clean_water_output returns: wu_clean;
		create water_unit number: type.polluted_water_output returns: wu_polluted {
			polluted <- true;
		}
		water_out.water_units <- water_out.water_units + list(wu_clean) + list(wu_polluted);	
	}
	
	action repair{
		if nb_repairing > 0 and (dysfunction)  {
			my_owner.money <- my_owner.money - type.money_cost;
			dysfunction <- false;
			nb_repairing <- nb_repairing - 1;
		}
	}
		
	action change_type {
		if (nb_activity_changeable > 0) {
			map input_values <- user_input([choose("New activity type", string,type.name, activity_type collect each.name)]);
			activity_type new_type <- activity_type first_with (each.name =  string(input_values at "New activity type"));
			if (new_type != type) {
				int change_cost <- type.money_cost + new_type.money_cost;
				my_owner.money  <- my_owner.money  - change_cost;
				type <- new_type;
				nb_activity_changeable <- nb_activity_changeable - 1;
			}	
		}
	}
		
		

	aspect default{
		draw line([location, input_node.location]) color: #green;
		draw line([location, output_node.location]) color: #red;
		draw shape color: color border: #black;
		if (is_selected) {
			draw shape.contour + 0.5 color: #magenta border: #black;
		}
	}
	
	aspect activity_type{
		draw line([location, input_node.location]) color: #green;
		draw line([location, output_node.location]) color: #red;
		draw shape color: type.color border: #black;
		if (is_selected) {
			draw shape.contour + 0.5 color: #magenta border: #black;
		}
		if dysfunction {
			draw triangle(shape.height * 0.8) color: #yellow border: #black;
			draw "!" anchor: #center color: #black font:font("Helvetica", shape.height * 2.5, #bold);
			
		}
	}
	

}

	
	
species activity_type {
	int clean_water_input <- 3;
	int polluted_water_input <- 1;
	int clean_water_output <- 0;
	int polluted_water_output <- 2;
	bool excessive_water <- false;
	bool excessive_pollution <- false;
	bool green_activity <- false;
	rgb color <- #yellow;
	int money_earned <- 3;
	int money_cost <- 2;
	string text_def;
	
	action initialize {
		shape <- rectangle(world.shape.width * 0.05, world.shape.height * 0.05) at_location {world.shape.width * 0.05, world.shape.height * 0.25 + int(self) * world.shape.width*0.035};
		text_def <- name + ": WI: " + (clean_water_input + polluted_water_input) + " PWI: " + polluted_water_input + " CWO: " + clean_water_output + " PWO: " + polluted_water_output + " MC: " + money_cost + " ME:" + money_earned;
	}
	
	aspect default {
		draw shape color: color border: #black ;
		draw text_def anchor: #left_center at: location + {shape.width,0} color: #white font:font("Helvetica", world.shape.width *0.11, #bold); 
	}
}

species owner {
	string id;
	list<activity> my_activities;
	int money <- 10;
	rgb color <- rnd_color(255);
}	

species button 
{
	int id <- int(self);
	rgb bord_col<-color_name[id];
	bool is_selected <- false;
	aspect normal {
		draw shape color: bord_col;
		draw shape.contour  + (shape.height * 0.01)   color: #white;
		if (is_selected) {draw shape.contour  + (shape.height * 0.05)   color: #red;}
		draw (text_name[id]) color: #white font:font("Helvetica", shape.width *0.8, #bold) anchor: #center;
	}
}


experiment serious_game type: gui autorun: true {
	float minimum_cycle_duration <- 0.25;
	
	output {
		layout #split;
	  
		display main_map {
			
			species intersection aspect: network;
			species intersection aspect: circle;
			species activity aspect: activity_type;
			species water aspect: quantity_quality;
			
			
			event mouse_down action:activity_management;
		}
		
		
		//display the action buttons
		display action_buton background:#black name:"Tools panel"  	{
			graphics "Information" {
				draw "Turn " + turn color: #white at: {world.shape.width/2.0, world.shape.height/10.0} font:font("Helvetica", world.shape.width *0.3, #bold) anchor: #center; 
				draw "You can still repair " + nb_repairing + " activities" color: #white at: {world.shape.width/2.0, 2*world.shape.height/10.0} font:font("Helvetica", world.shape.width *0.2, #bold) anchor: #center; 
				
				draw "You can still change " + nb_activity_changeable + " activity types" color: #white at: {world.shape.width/2.0, 3* world.shape.height/10.0} font:font("Helvetica", world.shape.width *0.2, #bold) anchor: #center; 
			}
			species button aspect:normal ;
			event mouse_down action:activate_act;    
		}
		
		display activity_types background:#black name:"List of activity types"  	{
			graphics "title" {
				draw "List of Activity types " color: #white at: {world.shape.width/2.0, world.shape.height/20.0} font:font("Helvetica", world.shape.width *0.25, #bold) anchor: #center; 
				draw "CWI: min water input; PWI: max polluted water input;  CWO: clean water output;" color: #white at: {world.shape.width/2.0, world.shape.height * 0.9} font:font("Helvetica", world.shape.width *0.08) anchor: #center; 
				draw "PWO: polluted water output; MC: money_cost; ME: money_earned" color: #white at: {world.shape.width/2.0, world.shape.height * 0.95} font:font("Helvetica", world.shape.width *0.08) anchor: #center; 
			
			}
			species activity_type;   
		}
		
		display charts refresh: player_turn{ 
			chart "Water quantity" type: series background: rgb('white') size: {1,0.5} position: {0, 0} {
				data "Total water quantity" value: water_quantity color: rgb('blue') ;
				data "Clean water quantity" value: water_quantity * water_quality color: rgb('green') ;
				data "Polluted water quantity" value: water_quantity * (1 - water_quality) color: rgb('red') ;
			}
			chart "Money of the owners" type: series background: rgb('white') size: {1,0.5} position: {0, 0.5} {
				data "Mean money" value: mean_money color: rgb('black') ;
				data "Min money" value: min_money  color: rgb('red') ;
				data "Max money" value: max_money  color: rgb('green') ;
			}	
		}
		
	}

}
	

	
experiment calibration type: batch repeat: 5 keep_seed: true until: ( time > 15 ) {
	parameter 'Quantity of input water North' var: input_water_quantity_north min: 10 max: 30 step: 1;
	parameter 'Quantity of input water South' var: input_water_quantity_south min: 10 max: 30 step: 1 ;
	parameter save_results var: save_results <- true among: [true];
	parameter interactive_mode var: interactive_mode <- false among: [false];
	parameter input_water_quantity_norths var: input_water_quantity_norths <- [];
	
	parameter input_water_quantity_souths var: input_water_quantity_souths <- [];
	method genetic minimize: abs(output_water_quantity_real - output_water_quantity_wished) improve_sol: true pop_dim: 10 max_gen: 50;
	
	reflex show_results{
		write sample(input_water_quantity_north) + " " + sample(input_water_quantity_south) +" error: " + simulations mean_of (abs(each.output_water_quantity_real - each.output_water_quantity_wished)) ;
	}
}
	
	
	