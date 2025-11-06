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

/// Transforms a private internal function to accept ContractSelf as first parameter and returns
/// the complete function definition as a quote. Internal functions are NOT entry points.
pub(crate) comptime fn generate_private_internal(f: FunctionDefinition) -> Quoted {
    let module_has_storage = module_has_storage(f.module());
    let storage_type = get_storage_type_in_module(f.module());

    let original_function_name = f.name();
    let return_type = f.return_type();

    // Build the parameters: self comes first, then original params
    let original_params = f
        .parameters()
        .map(|(param_name, param_type)| quote { $param_name: $param_type })
        .join(quote {, });

    let params = quote {
        context: &mut aztec::context::private_context::PrivateContext,
        $original_params
    };

    let body = f.body();
    let fn_name = f"__aztec_nr_internals__{original_function_name}".quoted_contents();

    // Internal functions are regular functions, not entry points
    // We mark them with #[contract_library_method] to prevent them from being compiled as entry points
    quote {
        #[contract_library_method]
        fn $fn_name($params) -> $return_type {
            #[allow(unused_variables)]
            let mut self = {
                $storage_init
                let self_address = context.this_address();
                let call_self: CallSelf<&mut aztec::context::private_context::PrivateContext> = CallSelf { address: self_address, context: &mut context };
                let enqueue_self: EnqueueSelf<&mut aztec::context::private_context::PrivateContext> = EnqueueSelf { address: self_address, context: &mut context };
                let call_self_static: CallSelfStatic<&mut aztec::context::private_context::PrivateContext> = CallSelfStatic { address: self_address, context: &mut context };
                let enqueue_self_static: EnqueueSelfStatic<&mut aztec::context::private_context::PrivateContext> = EnqueueSelfStatic { address: self_address, context: &mut context };
                let internal: CallInternal<&mut aztec::context::private_context::PrivateContext> = CallInternal { context: &mut context };
                aztec::contract_self::ContractSelf::new_private(&mut context, storage, call_self, enqueue_self, call_self_static, enqueue_self_static, internal)
            };
            
            $body
        }
    }
}

/// Transforms a public internal function to accept ContractSelf as first parameter and returns
/// the complete function definition as a quote. Internal functions are NOT entry points.
pub(crate) comptime fn generate_public_internal(f: FunctionDefinition) -> Quoted {
    let module_has_storage = module_has_storage(f.module());
    let storage_type = get_storage_type_in_module(f.module());

    let original_function_name = f.name();
    let return_type = f.return_type();

    // Build the parameters: self comes first, then original params
    let original_params = f
        .parameters()
        .map(|(param_name, param_type)| quote { $param_name: $param_type })
        .join(quote {, });

    let params = quote {
        context: aztec::context::public_context::PublicContext,
        $original_params
    };

    let body = f.body();
    let fn_name = f"__aztec_nr_internals__{original_function_name}".quoted_contents();

    // Internal functions are regular functions, not entry points
    // We mark them with #[contract_library_method] to prevent them from being compiled as entry points
    quote {
        #[contract_library_method]
        unconstrained fn $fn_name($params) -> pub $return_type {
            #[allow(unused_variables)]
            let mut self = {
                $storage_init
                let self_address = context.this_address();
                let call_self: CallSelf<aztec::context::public_context::PublicContext> = CallSelf { address: self_address, context };
                let call_self_static: CallSelfStatic<aztec::context::public_context::PublicContext> = CallSelfStatic { address: self_address, context };
                let internal: CallInternal<aztec::context::public_context::PublicContext> = CallInternal { context };
                aztec::contract_self::ContractSelf::new_public(context, storage, call_self, call_self_static, internal)
            };

            $body
        }
    }
}
