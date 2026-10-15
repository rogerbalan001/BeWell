import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PagosService } from './application/pagos.service';
import { PasarelaPagos } from './application/pasarela-pagos';
import { PagoRepository } from './domain/pago.repository';
import { MongoPagoRepository } from './infrastructure/mongo-pago.repository';
import { PagoDoc, PagoSchema } from './infrastructure/pago.schema';
import { PasarelaSimuladaAdapter } from './infrastructure/pasarela-simulada.adapter';
import { PagosController } from './interface/pagos.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: PagoDoc.name, schema: PagoSchema }])],
  controllers: [PagosController],
  providers: [
    PagosService,
    { provide: PagoRepository, useClass: MongoPagoRepository },
    { provide: PasarelaPagos, useClass: PasarelaSimuladaAdapter },
  ],
  exports: [PagosService],
})
export class PagosModule {}
