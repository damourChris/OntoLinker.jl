module OntoLinker

using Comonicon
using Configurations
using LightXML
using Graphs
using MetaGraphs
using OntologyLookup
using TOML
import Base.get!

include("config.jl")
include("utils.jl")
include("functions.jl")

"""
Genreates an ontology graph from the input iris.

# Arguments
- `iristream::String`: The input iris stream.

# Options
- `-c, --config-file`: The configuration file. If not provided, the default configuration is used.

# Flags
- `-f, --file`: If set, the input iris is a file path. 
"""
@main function onto_linker(iristream::String; file::Bool=false,
    config_file::String="")
    # If the config file is not provided, use the default configuration
    if isempty(config_file)
        config = Config()
    else
        # Load the configuration from the TOML file
        config = load_config(config_file)
    end

    # Load the iris 
    if file
        @debug "Reading iris from file: $iristream"
        # Check that the file exists
        if !isfile(iristream)
            @error "File not found: $iristream"
            exit(1)
        end

        iris = parse_iris(open(iristream))
    else
        @debug "Reading iris from input stream"
        iris = parse_iris(IOBuffer(iristream))
    end

    @debug "Loaded $(length(iris)) iris"
    if length(iris) < 5
        @debug iris
    else
        @debug iris[1:5] * "..."
    end

    # Generate graph using the loaded configuration
    return generate_graph(iris, config)
end

end
