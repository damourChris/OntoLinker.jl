
"""
    get_tree_from_term_id(term_id::String; ontology_id="cl")

Get the ontology tree for a given term id. It fetches the term from the OLS API and constructs
the tree structure for the term. It returns the tree with the indexing property set to iri.
"""
function get_tree_from_term_id(term_id::String; ontology_id="cl")
    @debug "Fetching term information for term_id: $term_id, ontology_id: $ontology_id"
    term = onto_term(ontology_id, term_id)

    @debug "Constructing tree for term: $term"
    tree = get_tree(term)
    set_indexing_prop!(tree, :iri)
    return tree
end

# Define a function to expand the proporties of each vertex in the graph with the properties of the term
"""
    expand_vertex_properties!(graph::MetaDiGraph, terms::Vector{Term})

Expand the properties of each vertex in the graph with the properties of the term. It iterates
through each term in the input list and finds the corresponding vertex in the graph. If the vertex
is found, it expands its properties with the given term properties.
"""
function expand_vertex_properties!(graph::MetaDiGraph)
    @debug "Expanding vertex properties with term properties of $(length(terms)) terms"
    terms = [onto_term(onto, iri) for (onto, iri) in get_iris_from_props(graph)]

    for term in terms
        # Find the vertex in the graph that corresponds to the term
        vertex_id = graph[term.iri, :iri]

        # If the vertex is found, expand its properties with the term properties
        if !isnothing(vertex_id)
            dict_term = Dict(field => getfield(term, field) for field in fieldnames(Term))
            graph.vprops[vertex_id] = merge(graph.vprops[vertex_id], dict_term)
        end
    end
end

"""
    merge_metagraphs(graphs::Vector{MetaDiGraph})

Merge multiple MetaDiGraphs into a single MetaDiGraph. It iterates through each graph in the 
input list and adds the nodes and edges to the merged graph. If a node or edge already exists 
in the merged graph, the properties are merged. If a node or edge does not exist, it is added 
to the merged graph.
"""
function merge_metagraphs(graphs)
    @debug "Merging $(length(graphs)) graphs"
    # Initialize an empty graph to store the result
    merged_graph = MetaDiGraph()
    set_indexing_prop!(merged_graph, :iri)

    # Iterate through each graph in the input list
    for graph in graphs
        # Add nodes from the current graph to the merged graph
        for node_props in values(graph.vprops)
            iri = node_props[:iri]
            node_id = try
                merged_graph[iri, :iri]
            catch
                nothing
            end

            if isnothing(node_id)
                # Add the node to the merged graph
                add_vertex!(merged_graph, node_props)
            else
                # Merge the properties of the node
                merged_graph.vprops[node_id] = merge(merged_graph.vprops[node_id],
                    node_props)
            end
        end

        # Add edges from the current graph to the merged graph
        for (edge, props) in graph.eprops
            # For each edge, find the source and target nodes in the merged graph

            sourceid = try
                merged_graph[graph[edge.src, :iri], :iri]
            catch
                nothing
            end
            targetid = try
                merged_graph[graph[edge.dst, :iri], :iri]
            catch
                nothing
            end

            # If either the source or target node is not found, add them to the graph 
            isnothing(sourceid) && add_vertex!(merged_graph, graph.vprops[edge.src])
            isnothing(targetid) && add_vertex!(merged_graph, graph.vprops[edge.dst])

            new_sourceid = merged_graph[graph[edge.src, :iri], :iri]
            new_targetid = merged_graph[graph[edge.dst, :iri], :iri]

            add_edge!(merged_graph, new_sourceid, new_targetid, props)
        end
    end

    return merged_graph
end

"""
    generate_graph(base_iris::Vector{String}, config::Config)

Generate a graph from the input strings in the configuration. It fetches the ontology tree for each
term, merges the trees together, populates the vertex properties with the term properties, and saves
the graph to a file. It returns the generated graph.

If the verbose flag is set in the configuration, it prints the progress messages.

# See also:
- [`get_tree_from_term_id`](@ref)
- [`merge_metagraphs`](@ref)
- [`expand_vertex_properties!`](@ref)
- [`export_to_graphxml`](@ref)
"""
function generate_graph(base_iris::Vector{String}, config::Config)
    @info "Generating graph with $(length(base_iris)) strings"

    # Step 1: Get the ontology tree for each term
    @debug "Fetching trees for each term for $(length(base_iris)) strings"
    trees = get_tree_from_term_id.(base_iris)

    ## Step 2: Merge the trees together
    graph = merge_metagraphs(trees)

    ## Step 3: Populate the vertex properties with the term properties fetched from OLS
    expand_vertex_properties!(graph)

    ## Step 4: Save the graph to a file
    export_to_graphxml(graph, config.output_file)

    @info "Graph generated! Info: $(graph)"
    @info "Graph saved to $(config.output_file)"
end