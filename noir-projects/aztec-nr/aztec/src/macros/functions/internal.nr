use crate::macros::utils::module_has_storage;

/// Returns the contract's module storage type, or unit type `()` if no storage is found.
comptime fn get_storage_type_in_module(m: Module) -> Type {
    let mut result = Option::none();
    for s in m.structs() {
        if s.has_named_attribute("storage") | s.has_named_attribute("storage_no_init") {
            result = Option::some(s.as_type());
        }
    }
    result.unwrap_or(quote { () }.as_type())
}

/// Injects `self: ContractSelf<&mut PrivateContext, Storage, CallSelf, EnqueueSelf, CallSelfStatic, EnqueueSelfStatic>`
/// (or uses `()` instead of `Storage` if the contract doesn't have Storage defined) as the first argument of the
/// `#[internal("private")]` function we are transforming. `Storage` here refers to the storage struct defined in the contract.
pub(crate) comptime fn transform_private_internal(f: FunctionDefinition) {
    let storage_type = get_storage_type_in_module(f.module());

    let original_params = f.parameters();

    f.set_parameters(&[(
        quote { &mut self },
        quote {
            crate::contract_self::ContractSelf<
                &mut crate::context::private_context::PrivateContext,
                $storage_type,
                CallSelf<&mut crate::context::private_context::PrivateContext>,
                EnqueueSelf<&mut crate::context::private_context::PrivateContext>,
                CallSelfStatic<&mut crate::context::private_context::PrivateContext>,
                EnqueueSelfStatic<&mut crate::context::private_context::PrivateContext>
            >
        }
            .as_type(),
    )]
        .append(original_params));
}

/// Injects `self: ContractSelf<&mut PublicContext, Storage>` (or `()` instead of `Storage` if the contract doesn't
/// have Storage defined) as the first argument of the `#[internal("public")]` function we are transforming. `Storage`
/// here refers to the storage struct defined in the contract.
pub(crate) comptime fn transform_public_internal(f: FunctionDefinition) {
    let storage_type = get_storage_type_in_module(f.module());

    let context_type = quote { crate::context::public_context::PublicContext }.as_type();
    let storage_type_with_context = quote { $storage_type<$context_type> }.as_type();

    let original_params = f.parameters();
    f.set_parameters(&[(
        quote { self },
        quote { crate::contract_self::ContractSelf<$context_type, $storage_type_with_context> }
            .as_type(),
    )]
        .append(original_params));
}
