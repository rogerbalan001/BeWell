import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { PagosService } from './application/pagos.service';
import { PasarelaPagos } from './application/pasarela-pagos';
import { PagoRepository } from './domain/pago.repository';
import { MongoPagoRepository } from './infrastructure/mongo-pago.repository';
import { PagoDoc, PagoSchema } from './infrastructure/pago.schema';
import { PasarelaPayPalAdapter } from './infrastructure/pasarela-paypal.adapter';
import { PasarelaSimuladaAdapter } from './infrastructure/pasarela-simulada.adapter';
import { PagosController } from './interface/pagos.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: PagoDoc.name, schema: PagoSchema }])],
  controllers: [PagosController],
  providers: [
    PagosService,
    { provide: PagoRepository, useClass: MongoPagoRepository },
    // PAGOS_PROVEEDOR=paypal usa PayPal (sandbox por defecto); cualquier otro valor, la pasarela simulada.
    {
      provide: PasarelaPagos,
      inject: [ConfigService],
      useFactory: (config: ConfigService): PasarelaPagos =>
        (config.get<string>('PAGOS_PROVEEDOR') ?? 'simulada').toLowerCase() === 'paypal'
          ? new PasarelaPayPalAdapter(config)
          : new PasarelaSimuladaAdapter(),
    },
  ],
  exports: [PagosService],
})
export class PagosModule {}
