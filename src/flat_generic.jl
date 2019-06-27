const FlatField{P,T,M} = Union{FlatS0{P,T,M},FlatS2{P,T,M}}

### promotion
function promote(f1::F1, f2::F2) where {T1,θ1,N1,∂mode1,F1<:FlatS0{Flat{N1,θ1,∂mode1},T1},T2,θ2,N2,∂mode2,F2<:FlatS0{Flat{θ2,N2,∂mode2},T2}}
    T     = promote_type(T1,T2)
    B     = promote_type(basis(F1),basis(F2))
    ∂mode = promote_type(∂mode1,∂mode2)
    B(T(∂mode(f1))), B(T(∂mode(f2)))
end

### conversion
(::Type{T})(f::FlatMap{P}) where {T<:Real,P} =  FlatMap{P}(T.(f.Ix))
(::Type{T})(f::FlatFourier{P}) where {T<:Real,P} =  FlatFourier{P}(Complex{T}.(f.Il))
(::Type{∂mode})(f::F) where {∂mode<:∂modes,θ,N,F<:FlatS0{<:Flat{θ,N}}} = basetype(F){Flat{θ,N,∂mode}}(fieldvalues(f)...)
FFTgrid(::FlatS0{P,T}) where {P,T} = FFTgrid(P,T)

### basis-like definitions
LenseBasis(::Type{<:FlatS0}) = Map
LenseBasis(::Type{<:FlatS2}) = QUMap
DerivBasis(::Type{<:FlatS0{<:Flat{<:Any,<:Any,fourier∂}}}) =   Fourier
DerivBasis(::Type{<:FlatS2{<:Flat{<:Any,<:Any,fourier∂}}}) = QUFourier

### derivatives
broadcastable(::Type{<:FlatFourier{P,T}}, ::∇diag{1,<:Any,prefactor}) where {P,T,prefactor} = 
    @. prefactor * im * FFTgrid(P,T).k'
broadcastable(::Type{<:FlatFourier{P,T}}, ::∇diag{2,<:Any,prefactor}) where {P,T,prefactor} = 
    @. prefactor * im * FFTgrid(P,T).k[1:Nside(P)÷2+1]


# @generated function broadcast_data(::Type{<:BaseFlatFourier{T,P}}, ::∇²Op) where {coord,T,P}
#     (FFTgrid(P,T).k' .^2 .+ FFTgrid(P,T).k[1:Nside(P)÷2+1].^2,)
# end
# mul!( f′::F, ∇i::Union{∇i,AdjOp{<:∇i}}, f::F) where {T,θ,N,F<:FlatFourier{T,<:Flat{θ,N,<:fourier∂}}} = @. f′ = ∇i * f
# ldiv!(f′::F, ∇i::Union{∇i,AdjOp{<:∇i}}, f::F) where {T,θ,N,F<:FlatFourier{T,<:Flat{θ,N,<:fourier∂}}} = @. f′ = ∇i \ f
# 
# # map space derivatives
# DerivBasis(::Type{<:FlatS0{T,Flat{θ,N,map∂}}}) where {T,θ,N} = Map
# DerivBasis(::Type{<:FlatS2{T,Flat{θ,N,map∂}}}) where {T,θ,N} = QUMap
# function mul!(f′::F, ∇::Union{∇i{coord},AdjOp{<:∇i{coord}}}, f::F) where {coord,T,θ,N,F<:FlatS0Map{T,<:Flat{θ,N,<:map∂}}}
#     n,m = size(f.Tx)
#     Δx = FFTgrid(f).Δx #* (∇ isa AdjOp ? -1 : 1) why doesn't this need to be here???
#     if coord==0
#         @inbounds for j=2:m-1
#             @simd for i=1:n
#                 f′.Tx[i,j] = (f.Tx[i,j+1] - f.Tx[i,j-1])/2Δx
#             end
#         end
#         @inbounds for i=1:n
#             f′.Tx[i,1] = (f.Tx[i,2]-f.Tx[i,end])/2Δx
#             f′.Tx[i,end] = (f.Tx[i,1]-f.Tx[i,end-1])/2Δx
#         end
#     elseif coord==1
#         @inbounds for j=1:n
#             @simd for i=2:m-1
#                 f′.Tx[i,j] = (f.Tx[i+1,j] - f.Tx[i-1,j])/2Δx
#             end
#             f′.Tx[1,j] = (f.Tx[2,j]-f.Tx[end,j])/2Δx
#             f′.Tx[end,j] = (f.Tx[1,j]-f.Tx[end-1,j])/2Δx
#         end
#     end
#     f′
# end
# function mul!(f′::F, ∇::Union{∇i{coord},AdjOp{<:∇i{coord}}}, f::F) where {coord,T,θ,N,F<:FlatS2Map{T,<:Flat{θ,N,<:map∂}}}
#     mul!(f′.Q, ∇, f.Q)
#     mul!(f′.U, ∇, f.U)
#     f′
# end
# 
# 
# bandpass
HarmonicBasis(::Type{<:FlatS0}) = Fourier
HarmonicBasis(::Type{<:FlatQU}) = QUFourier
HarmonicBasis(::Type{<:FlatEB}) = EBFourier
broadcastable(::Type{F}, bp::BandPass) where {P,T,F<:FlatFourier{P,T}} = Cℓ_to_2D(P,T,bp.Wℓ)
    

# logdets
logdet(L::DiagOp{<:FlatFourier})   = real(sum(nan2zero.(log.(unfold(L.diag.Tl)))))
logdet(L::DiagOp{<:FlatMap})       = real(sum(nan2zero.(log.(complex(L.diag.Tx)))))
logdet(L::DiagOp{<:FlatEBFourier}) = real(sum(nan2zero.(log.(unfold(L.diag.El))) + nan2zero.(log.(unfold(L.diag.Bl)))))

# always do dot product in map basis
dot(a::Field, b::Field) = Ł(a)[:] ⋅ Ł(b)[:]