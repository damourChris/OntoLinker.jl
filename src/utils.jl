function parse_iris(iristream::IO)
    # Read the iris from the input stream
    iris = read(iristream, String)

    # Split the iris by newline
    iris = split(iris, '\n')

    # Remove empty lines
    iris = filter(x -> !isempty(x), iris)

    return string.(iris)
end

# TODO: make this function more generic
"""
    export_to_graphxml(graph::MetaDiGraph, filename::String;
                            remove_fields=["description"])

Export a MetaDiGraph to a GraphML file. It creates an XML document with the graph structure
and saves it to the specified file. The function takes the graph and the filename as input
arguments. It also accepts an optional argument `remove_fields` to specify the fields that
should be removed from the graph properties before exporting.
"""
function export_to_graphxml(graph::MetaDiGraph, filename::String;
    remove_fields=["description"])
    xdoc = XMLDocument()

    # Create the root element
    xroot = create_root(xdoc, "graphml")
    set_attribute(xroot, "xmlns", "http://graphml.graphdrawing.org/xmlns")

    fnames = fieldnames(Term)

    # Filter the fieldnames to remove the fields that are not needed
    fnames = filter(x -> x ∉ remove_fields, fnames)

    # Create the key elements for the fieldnames
    for field in [fnames..., :label]
        xkey = new_child(xroot, "key")
        set_attribute(xkey, "id", field)
        set_attribute(xkey, "for", "node")
        set_attribute(xkey, "attr.name", field)
        set_attribute(xkey, "attr.type", "string")
    end

    # Define graph attributes
    xgraph = new_child(xroot, "graph")
    set_attribute(xgraph, "id", "G")
    set_attribute(xgraph, "edgedefault", "directed") # Assuming directed graph

    # Create data nodes 
    for (i, vprops) in graph.vprops
        xnode = new_child(xgraph, "node")
        set_attribute(xnode, "id", string(i))

        for field in fnames
            xdata = new_child(xnode, "data")
            set_attribute(xdata, "key", field)
            add_text(xdata, string(vprops[field]))
        end
    end

    # Add edges
    for e in edges(graph)
        xedge = new_child(xgraph, "edge")
        set_attribute(xedge, "source", string(src(e)))
        set_attribute(xedge, "target", string(dst(e)))
    end

    # Check if the file name has any directories in its path and if they all exist, if not create them
    if !isdir(dirname(filename))
        mkpath(dirname(filename))
    end

    # Save XML document to file
    return save_file(xdoc, filename)
end

"""
    get_iris_from_props(graph::MetaDiGraph)

Get the ontology and iri from the properties of the vertices in the graph. It iterates through
the properties of the vertices and extracts the ontology and iri. It returns a list of tuples
with the ontology and iri for each vertex.
"""
function get_iris_from_props(graph::MetaDiGraph)
    return [(split(split(d[:iri], "/")[end], "_")[1], d[:iri])
            for d in values(graph.vprops)]
end
