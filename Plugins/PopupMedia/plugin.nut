////////////////////////////////////////////////////////////////

class UserConfig </ help="This plugin provides support for single image/video(single button show and hide) -- modified by Y3SS Created by joyrider - based on Sumatra plugin" />
{
	</ label="Path", help="Path to media - can include [Name], [Emulator], [Year], [Manufacturer], [System], [DisplayName]", order = 1 />
		path="media/[Emulator]";
	</ label="Show/Hide Key", help="Key to use to trigger displaying the media", options="custom1,custom2,custom3,custom4,custom5,custom6", order =2 />
		key="custom3";
	</ label="Missing Image", help="Path to 'missing' image - can include [Name], [Emulator], [Year], [Manufacturer], [System], [DisplayName]", order = 3 />
		missing="png/manual_not_found.png";
    </ label="ForEmulator", help="select media for emulator or games", options="Yes,No" , order = 4 />
		for_emulator="Yes";
	</ label="FileName", help="select media for emulator", order = 5 />
		FileName="Controls";
	</ label="Preserve aspect ratio Manual", help="Preserve aspect ratio of the media", options="Yes,No", order = 6 />
		preserve_aspect_ratio_manual= "Yes";
	</ label="Show background", help="Shows a background when Preserve aspect ratio is set overlaying the layout", options="Yes,No", order = 7 />
		show_background= "Yes";
	</ label="Background color", help="Color of the background to display when preserve aspect ratio is set", options="Black,White,Grey,Blue,Red,Yellow,Green,Magenta" ,order = 8 />
		background_color = "Black";
	</ label="Media Opacity", help="Apply transparancy to the manual (255 is fully visible)", options="25,50,75,100,125,150,175,200,225,255", order = 9 />
		manual_opacity = "255";
	</ label="Background Opacity", help="Apply transparancy to background (255 is fully visible)", options="25,50,75,100,125,150,175,200,225,255", order = 10 />
		background_opacity = "175";
}

fe.load_module("file");

local config = fe.get_config(); // get user config settings corresponding to the UserConfig class above

class PopupMedia
{
    _swf_visible = false;
    _initialized = false;
    _swf = {};
	_background = {};

    constructor()
    {
        fe.add_signal_handler(this, "on_signal")
        fe.add_transition_callback(this, "onTransition")
    }



    function file_exist(fullpathfilename) {
		try {
			file(fullpathfilename, "r" );
			return true;
		}
		catch(e) {
			return false;
		}
	}



    function on_signal(signal){

        if(_swf_visible == true && signal==config["key"]){
            _swf_visible = false;
            _swf.file_name = "";
            _swf.visible = _swf_visible;
            _background.visible = _swf_visible && (config["show_background"] == "Yes");
			print("cancle");
			return true;


        }

        if(_swf_visible == false && signal==config["key"]){
            local path = get_magic_token_path(config["path"]);
			local filename_noext ="";
             if(config["for_emulator"] =="Yes"){
                filename_noext = path + config["FileName"];
             }

            else{
                
			    filename_noext = path + fe.game_info(Info.Name);
            }

			local filename = find_filename_ext(filename_noext);
			local missing_path = get_magic_token_path(config["missing"]);
			local missing = missing_path.slice(0, missing_path.len() - 1);
			local exists = file_exist(filename);
              if(exists == false){
                _swf_visible = true;
				_swf.file_name = missing;
				_swf.visible = _swf_visible;
				_background.visible = _swf_visible && (config["show_background"] == "Yes");
              }
              else{
                 _swf_visible = true;
				//_swf.file_name = filename;
                _swf.file_name=fe.path_expand(filename);
				_swf.visible = _swf_visible;
				_background.visible = _swf_visible && (config["show_background"] == "Yes");
              }
            return true;
        }

		return false;




    }

    //replace specified magic tokens in path - taken from sumatrapdf plugin
	function get_magic_token_path(path) {
		local tokens = {
			"Name": fe.game_info(Info.Name),
			"Emulator": fe.game_info(Info.Emulator),
			"Year": fe.game_info(Info.Year),
			"Manufacturer": fe.game_info(Info.Manufacturer),
			"Category": fe.game_info(Info.Category),
			"System": fe.game_info(Info.System),
			"DisplayName": fe.list.name
		}
		foreach( key, val in tokens)
			path = replace(path, "[" + key + "]", val);

		//replace slashes with backslashes
		path = replace(path, "\\", "/");
		//ensure trailing slash
		local trailing = path.slice(path.len() - 1, path.len());
		if ( trailing != "/") path += "/";
		return path;
	}

    function file_exist(fullpathfilename) {
		try {
			file(fullpathfilename, "r" );
			return true;
		}
		catch(e) {
			return false;
		}
	}

    //replace all instances of 'find' in 'str' with 'repl' - taken from sumatrapdf plugin
	function replace(str, find, repl) {
		local start = str.find(find);
		if ( start != null ) {
			local end = start + find.len(); 
			local before = str.slice(0, start);
			local after = str.slice(end, str.len());
			str = before + repl + after;
			str = replace(str, find, repl);
		}
		return str;

    }

    function onTransition( ttype, var, transition_time ) {
		// Initialize on StartLayout
		if ((_initialized == false) && (ttype == Transition.StartLayout)) {
			return initializeArtwork();
		}
		
		//hide if going to a new game or launching etc
		if ((_initialized == true) && (ttype != Transition.StartLayout)) {
			_swf_visible = false;
			_background.visible = _swf_visible;
			_swf.visible = _swf_visible;
			_swf.file_name = "";
		}

		if ( ttype == Transition.ShowOverlay && (_initialized == true) ) {
        _swf_visible = false;
			_background.visible = _swf_visible;
			_swf.visible = _swf_visible;
			_swf.file_name = "";
    }

		return false;
	}

    function initializeArtwork() {
		if (_initialized) {
			return false;
		}

		_initialized = true;


		local mon = fe.monitors[0];

		_background = mon.add_text( "", 0, 0, fe.layout.width, fe.layout.height );
		_background.set_bg_rgb( 0, 0, 0 );
		if (config["background_color"] == "Blue")
		_background.set_bg_rgb(0, 0, 255);
		if (config["background_color"] == "Red")
		_background.set_bg_rgb(255, 0, 0);
		if (config["background_color"] == "White")
		_background.set_bg_rgb(255, 255, 255);
		if (config["background_color"] == "Yellow")
		_background.set_bg_rgb(255, 255, 0);
		if (config["background_color"] == "Magenta")
		_background.set_bg_rgb(255, 0, 255);
		if (config["background_color"] == "Green")
		_background.set_bg_rgb(0, 255, 0);
		if (config["background_color"] == "Grey")
		_background.set_bg_rgb(140, 140, 140);
		_background.bg_alpha = config["background_opacity"].tointeger();	
		_background.visible = false;

		_swf = mon.add_image("", 0, 0, fe.layout.width, fe.layout.height);
		_swf.visible = false;
		_swf.preserve_aspect_ratio = ( config["preserve_aspect_ratio_manual"] == "Yes" );
		_swf.alpha = config["manual_opacity"].tointeger();
		
		return false;
	}

    function find_filename_ext(root_filename) {
		if (file_exist(root_filename + ".mp4")) {
			return root_filename + ".mp4";
		}
		
		if (file_exist(root_filename + ".avi")) {
			return root_filename + ".avi";
		}
		
		if (file_exist(root_filename + ".bmp")) {
			return root_filename + ".bmp";
		}
		
		if (file_exist(root_filename + ".tga")) {
			return root_filename + ".tga";
		}
		
		if (file_exist(root_filename + ".png")) {
			return root_filename + ".png";
		}
		
		if (file_exist(root_filename + ".jpg")) {
			return root_filename + ".jpg";
		}
		
		if (file_exist(root_filename + ".jpeg")) {
			return root_filename + ".jpeg";
		}
		
		if (file_exist(root_filename + ".swf")) {
			return root_filename + ".swf";
		}
		
		if (file_exist(root_filename + ".gif")) {
			return root_filename + ".gif";
		}
		
		//return a filename we will never find
		return root_filename + ".zxyz";
	}



}

fe.plugin["PopupMedia"] <- PopupMedia();