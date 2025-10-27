use crate::macros::utils::module_has_storage;

/// Returns the storage type for internal functions based on whether the module has storage defined.
/// If the module has storage, returns `Storage`, otherwise returns `()`.
comptime fn get_storage_type_for_internal(f: FunctionDefinition) -> Quoted {
    let module_has_storage = module_has_storage(f.module());

    if module_has_storage {
        quote { Storage }
    } else {
        quote { () }
    }
}

/// Injects `self: ContractSelf<&mut PrivateContext, Storage>` (or `()` instead of `Storage` if the contract doesn't
/// have Storage defined) as the first argument of the `#[internal("private")]` function we are transforming. `Storage`
/// here refers to the storage struct defined in the contract.
pub(crate) comptime fn transform_private_internal(f: FunctionDefinition) {
    let storage_type = get_storage_type_for_internal(f);

    let original_params = f.parameters();
    f.set_parameters(&[(
        quote { &mut self },
        quote { crate::contract_self::ContractSelf<&mut crate::context::private_context::PrivateContext, $storage_type> }
            .as_type(),
    )]
        .append(original_params));
}

/// Injects `self: ContractSelf<&mut PublicContext, Storage>` (or `()` instead of `Storage` if the contract doesn't
/// have Storage defined) as the first argument of the `#[internal("public")]` function we are transforming. `Storage`
/// here refers to the storage struct defined in the contract.
pub(crate) comptime fn transform_public_internal(f: FunctionDefinition) {
    let storage_type = get_storage_type_for_internal(f);

    let original_params = f.parameters();
    f.set_parameters(&[(
        quote { &mut self },
        quote { crate::contract_self::ContractSelf<&mut crate::context::public_context::PublicContext, $storage_type> }
            .as_type(),
    )]
        .append(original_params));
}
