export PointMassConstraint

"""
Description:

    Constraints the marginal of the connected variable to a point-mass.
    
Interfaces:

    1. out

Construction:

    PointMassConstraint(out; id=:my_node)
"""
mutable struct PointMassConstraint <: DeltaFactor
    id::Symbol
    interfaces::Array{Interface,1}
    i::Dict{Symbol, Interface}

    function PointMassConstraint(out; id=ForneyLab.generateId(PointMassConstraint))
        @ensureVariables(out)
        self = new(id, Vector{Interface}(undef, 1), Dict{Symbol,Interface}())
        ForneyLab.addNode!(currentGraph(), self)
        self.i[:out] = self.interfaces[1] = associate!(Interface(self), out)

        return self
    end
end    

slug(::Type{PointMassConstraint}) = "δ"

# A breaker message is required if interface is partnered with a point-mass constraint
requiresBreaker(interface::Interface, partner_interface::Interface, partner_node::PointMassConstraint) = true

breakerParameters(interface::Interface, partner_interface::Interface, partner_node::PointMassConstraint) = (Message{GaussianMeanVariance, Univariate}, ()) # Univariate only

isPointMassConstraint(::PointMassConstraint) = true