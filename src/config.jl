
"""
    Config

Configuration object for the term process graph script.
"""
@option struct Config
    output_file::String = "graph.graphml"
end

"""
    load_config(file_path::String)::Config

Load the configuration from a TOML file. It reads the TOML file and extracts the input strings,
output file, and verbose flag from the configuration. It returns a Config object with the extracted
values.

If the file is not found or the TOML format is invalid, it prints an error message and exits the program.

Example TOML configuration file:
```
output_file = "graph.png"
```
"""
function load_config(file_path::String)::Config
    try
        config_dict = TOML.parsefile(file_path)

        config = from_dict(Config, config_dict)
        @debug "Loaded configuration: $config"
    catch e
        if isa(e, SystemError)
            @error "File not found: $file_path"
        elseif isa(e, TOML.ParserError)
            @error "Invalid TOML format in $file_path"
        else
            rethrow(e)
        end
        exit(1)
    end
end