# Functions for visualizing graphs
export graph2dot, graphPdf, graphViz

function graph2dot(nodes::Set{Node})
    # Return a string representing the graph that connects the nodes in DOT format for visualization.
    # http://en.wikipedia.org/wiki/DOT_(graph_description_language)
    node_type_symbols = {   AdditionNode => "+",
                            EqualityNode => "="}
    edges = getEdges(nodes, include_external=false)
    
    dot = "digraph G{splines=true;sep=\"+25,25\";overlap=scalexy;nodesep=1.6;compound=true;\n"
    dot *= "\tnode [shape=box, width=1.0, height=1.0, fontsize=9];\n"
    dot *= "\tedge [fontsize=8, arrowhead=onormal];\n"
    for node in nodes
        if typeof(node)==TerminalNode
            dot *= "\t$(object_id(node)) [label=\"$(node.name)\", style=filled, width=0.75, height=0.75]\n"
        else
            if haskey(node_type_symbols, typeof(node))
                dot *= "\t$(object_id(node)) [label=\"$(node_type_symbols[typeof(node)])\\n$(node.name)\"]\n"
            else
                dot *= "\t$(object_id(node)) [label=\"$(typeof(node))\\n$(node.name)\"]\n"
            end
        end
    end
    
    for edge in edges
        tail_id = findfirst(edge.tail.node.interfaces, edge.tail)
        tail_label = "$tail_id $(getName(edge.tail))"
        head_id = findfirst(edge.head.node.interfaces, edge.head)
        head_label = "$head_id $(getName(edge.head))"
        label =  string("FW: ", (edge.tail.message!=nothing) ? "&#9679;" : "&#9675;", " $(edge.tail.message_payload_type)\n")
        label *= string("BW: ", (edge.head.message!=nothing) ? "&#9679;" : "&#9675;", " $(edge.head.message_payload_type)\n")
        label *= haskey(factorization, edge) ? string("Subgraph: ", factorization[edge]) : string("")
        dot *= "\t$(object_id(edge.tail.node)) -> $(object_id(edge.head.node)) " 
        dot *= "[taillabel=\"$(tail_label)\", headlabel=\"$(head_label)\", label=\"$(label)\"]\n"
    end
    
    dot *= "}";
    
    return dot
end

function graph2dot(composite_node::CompositeNode)
    # Return graph2dot(nodes) where nodes are the internal nodes of composite_node
    nodes = Set{Node}()
    for field in names(composite_node)
        if typeof(getfield(composite_node, field)) <: Node
            push!(nodes, getfield(composite_node, field))
        end
    end
    (length(nodes) > 0) || error("CompositeNode does not contain any internal nodes.")

    return graph2dot(nodes, factorization)
end
graph2dot(graph::FactorGraph) = graph2dot(getNodes(graph, open_composites=false))
graph2dot() = graph2dot(getCurrentGraph())
graph2dot(subgraph::Subgraph) = graph2dot(getNodes(subgraph, open_composites=false))

function graphViz(n::Union(FactorGraph, Subgraph, CompositeNode, Set{Node}); external_viewer::Bool=false)
    # Generates a DOT graph and shows it
    validateGraphVizInstalled() # Show an error if GraphViz is not installed correctly
    dot_graph = graph2dot(n, factorization)
    if external_viewer
        viewDotExternal(dot_graph)
    else
        try
            # For iJulia notebook
            display("image/svg+xml", dot2svg(dot_graph))
        catch
            viewDotExternal(dot_graph)
        end
    end
end
graphViz(nodes::Vector{Node}; args...) = graphViz(Set(nodes); args...)
graphViz(; args...) = graphViz(getCurrentGraph(); args...)

function graphPdf(n::Union(FactorGraph, Subgraph, CompositeNode, Set{Node}), filename::String)
    # Generates a DOT graph and writes it to a pdf file
    validateGraphVizInstalled() # Show an error if GraphViz is not installed correctly
    dot_graph = graph2dot(n)
    stdin, proc = writesto(`dot -Tpdf -o$(filename)`)
    write(stdin, dot_graph)
    close(stdin)
end
graphPdf(nodes::Vector{Node}, filename::String) = graphPdf(Set(nodes), filename)
graphPdf(filename::String) = graphPdf(getCurrentGraph(), filename)

function dot2svg(dot_graph::String)
    # Generate SVG image from DOT graph
    validateGraphVizInstalled() # Show an error if GraphViz is not installed correctly
    stdout, stdin, proc = readandwrite(`dot -Tsvg`)
    write(stdin, dot_graph)
    close(stdin)
    return readall(stdout)
end

function validateGraphVizInstalled()
    # Check if GraphViz is installed
    try
        (readall(`dot -?`)[1:10] == "Usage: dot") || error()
    catch
        error("GraphViz is not installed correctly. Make sure GraphViz is installed. If you are on Windows, manually add the path to GraphViz to your path variable. You should be able to run 'dot' from the command line.")
    end
end

viewDotExternal(dot_graph::String) = (@windows? viewDotExternalImage(dot_graph::String) : viewDotExternalInteractive(dot_graph::String))

function viewDotExternalInteractive(dot_graph::String)
    # View a DOT graph in interactive viewer
    validateGraphVizInstalled() # Show an error if GraphViz is not installed correctly
    open(`dot -Tx11`, "w", STDOUT) do io
        println(io, dot_graph)
    end
end

function viewDotExternalImage(dot_graph::String)
    # Write the image to a file and open it with the default image viewer
    svg = dot2svg(dot_graph)
    filename = tempname()*".svg"
    open(filename, "w") do f
        write(f, svg)
    end
    viewFile(filename)
end