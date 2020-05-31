"""
	ArrayFuse{AT, T, P} <: AbstractArray{T, 1}

GPU Friendly type to wrap around two arrays - `visible` and `hidden`, for which when we `setindex!` some value `v` at index `i`
we get

```
visible[i] = p[1] * visible[i] + p[2] * v
hidden[i] = hidden[i] + p[3] * visible[i]
```

where p is a parameter tuple of size 3.
"""
struct ArrayFuse{AT, T, P} <: AbstractArray{T, 1}
	visible::AT
	hidden::AT
	p::P
end

ArrayFuse(visible::AT, hidden::AT, p) where {AT} = ArrayFuse{AT, eltype(visible), typeof(p)}(visible, hidden, p)

@inline function Base.copyto!(af::OrdinaryDiffEq.ArrayFuse{AT, T, P}, src::Base.Broadcast.Broadcasted) where {AT, T, P}
	@. af.visible = af.p[1] * af.visible + af.p[2] * src
	@. af.hidden = af.hidden + af.p[3] * af.visible
end

# not recommended but good to have
@inline function Base.getindex(af::ArrayFuse, index)
	return af.visible[index]
end

@inline function Base.setindex!(af::ArrayFuse, value, index)
	af.visible[index] = af.p[1] * af.visible[index] + af.p[2] * value
	af.hidden[index] = af.hidden[index] + af.p[3] * af.visible[index]
end

@inline Base.size(af::ArrayFuse) = length(af.visible)
@inline Base.axes(af::ArrayFuse) = axes(af.visible)

Adapt.adapt_structure(to, af::ArrayFuse{AT, T, P}) where {AT, T, P} = 
	ArrayFuse(adapt(to, af.visible), adapt(to, af.hidden), af.p)
